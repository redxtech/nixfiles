{ config, lib, pkgs, ... }:

let
  cfg = config.monitoring;
  cfgNet = config.network;
  cfgNAS = config.nas;
  inherit (cfg) ports;
  inherit (cfgNet) hostname;
  inherit (lib) mkIf mkOption mkEnableOption types;

  grafanaHost = "quasar";
  p = toString;
in {
  options.monitoring = {
    enable = mkEnableOption "Enable monitoring";

    isHost = mkOption {
      type = types.bool;
      default = false;
      description = "Whether the system is a host";
    };

    ports = let
      mkPort = port:
        mkOption {
          type = types.int;
          default = port;
          description = "The port to listen on";
        };
    in {
      grafana = mkPort 3000;
      prometheus = mkPort 3001;
      loki = mkPort 3002;
      alloy = mkPort 12346;
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [
    (mkIf cfg.isHost {
      # enable grafana and prometheus on host
      services.grafana = {
        enable = true;

        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = ports.grafana;
            # Grafana needs to know on which domain and URL it's running
            domain = grafanaHost;
          };

          smtp = {
            enabled = true;
            from_address = "grafana@sucha.foo";
            host = "$__file{${config.sops.secrets.grafana_smtp_host.path}}";
            user = "$__file{${config.sops.secrets.grafana_smtp_user.path}}";
            password = "$__file{${config.sops.secrets.grafana_smtp_pw.path}}";
          };
        };
      };

      # enable prometheus
      services.prometheus = {
        enable = true;
        port = ports.prometheus;

        extraFlags = [ "--web.enable-remote-write-receiver" ];
      };

      # enable loki
      services.loki = let inherit (config.services.loki) dataDir;
      in {
        enable = true;

        configuration = {
          auth_enabled = false;
          server.http_listen_port = ports.loki;

          common = {
            ring = {
              instance_addr = "0.0.0.0";
              kvstore = { store = "inmemory"; };
            };
            replication_factor = 1;
            path_prefix = "${dataDir}/loki";
          };

          schema_config.configs = [{
            from = "2024-06-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];

          storage_config.filesystem.directory = "${dataDir}/chunks";
        };

        extraFlags = [ "--server.http-listen-port=${toString ports.loki}" ];
      };

      # set grafana to use allow-iframe middleware
      services.traefik.dynamicConfigOptions.http.routers.grafana.middlewares =
        [ "homeassistant-allow-iframe" ];

      sops.secrets = let
        mkSecret = {
          sopsFile = ../../../hosts/quasar/secrets.yaml;
          group = config.users.users.grafana.group;
          mode = "0440";
        };
      in {
        grafana_smtp_pw = mkSecret;
        grafana_smtp_user = mkSecret;
        grafana_smtp_host = mkSecret;
      };
    })

    {
      # enable grafana alloy on non-hosts
      services.alloy = {
        enable = true;

        extraFlags = [ "--server.http.listen-addr=0.0.0.0:${p ports.alloy}" ];

        configPath = let
          mkScraper = name: address: ''
            prometheus.scrape "${name}" {
              targets     = [{ __address__   = "${address}" }]
              job_name    = "integrations/${name}"
              forward_to  = [prometheus.relabel.filter_metrics.receiver]
            }
          '';
          mkLocalScraper = name: port:
            mkScraper name "127.0.0.1:${toString port}";
          mkExportarr = name: port: mkLocalScraper "${name}_exportarr" port;

          alloyConfig = pkgs.writeText "alloy-config.json"
            (builtins.concatStringsSep "\n" [
              ''
                prometheus.exporter.unix "${hostname}" { }

                prometheus.scrape "scrape_metrics" {
                  targets         = prometheus.exporter.unix.${hostname}.targets
                  forward_to      = [prometheus.relabel.filter_metrics.receiver]
                  scrape_interval = "10s"
                }

                prometheus.scrape "${hostname}_docker" {
                  targets    = discovery.docker.${hostname}.targets
                  forward_to = [prometheus.relabel.filter_metrics.receiver]
                }
              ''
              (mkLocalScraper "docker" 9323)
              (mkLocalScraper "traefik" 8080)
              (mkLocalScraper "coredns" 3201)
              (mkLocalScraper "adguard" 3202)
              (mkLocalScraper "unpoller" 9130)
              (mkLocalScraper "navidrome" 4533)
              (mkExportarr "sonarr" 9707)
              (mkExportarr "radarr" 9708)
              ''
                prometheus.relabel "filter_metrics" {
                  rule {
                    action        = "drop"
                    source_labels = ["env"]
                    regex         = "dev"
                  }

                  forward_to = [prometheus.remote_write.metrics_service.receiver]
                }

                prometheus.remote_write "metrics_service" {
                  endpoint {
                    url = "http://${grafanaHost}:${
                      p ports.prometheus
                    }/api/v1/write"
                  }
                }
              ''
              ''
                discovery.docker "${hostname}" {
                  host = "unix:///var/run/docker.sock"
                }

                discovery.relabel "docker" {
                  targets = [{ __address__ = "unix:///var/run/docker.sock" }]
                  rule {
                    source_labels = ["__meta_docker_container_name"]
                    regex         = "/(.*)"
                    target_label  = "container_name"
                  }
                  rule {
                    source_labels = ["__meta_docker_container_id"]
                    target_label  = "container_id"
                  }
                }

                discovery.relabel "journal" {
                  targets = []
                  rule {
                    source_labels = ["__journal_systemd_unit"]
                    target_label  = "unit"
                  }
                }
              ''
              ''
                local.file_match "local_files" {
                  path_targets = [{
                    "__path__" = "/var/log/*.log",
                    "job"      = "varlogs",
                  }]
                  sync_period  = "5s"
                }

                loki.source.file "log_scraper" {
                  targets       = local.file_match.local_files.targets
                  forward_to    = [loki.process.filter_logs.receiver]
                  tail_from_end = true
                }

                loki.process "filter_logs" {
                  stage.drop {
                    source              = ""
                    expression          = ".*Connection closed by authenticating user root"
                    drop_counter_reason = "noisy"
                  }
                  stage.static_labels {
                    values = {
                      "app"  = "varlogs",
                      "host" = "${hostname}",
                    }
                  }
                  forward_to = [loki.write.grafana_loki.receiver]
                }
              ''
              ''
                loki.source.docker "docker_logs" {
                  host       = "unix:///var/run/docker.sock"
                  targets    = discovery.docker.${hostname}.targets
                  labels     = {
                    "app"  = "docker",
                    "host" = "${hostname}",
                  }
                  forward_to    = [loki.write.grafana_loki.receiver]
                  relabel_rules = discovery.relabel.docker.rules
                }

                loki.source.journal "${hostname}_journal" {
                  forward_to    = [loki.write.grafana_loki.receiver]
                  relabel_rules = discovery.relabel.journal.rules
                  labels        = {
                    "app"  = "journal",
                    "host" = "${hostname}",
                  }
                }
              ''
              ''
                loki.write "grafana_loki" {
                  endpoint {
                    url = "http://${grafanaHost}:${
                      p ports.loki
                    }/loki/api/v1/push"
                  }
                }
              ''
            ]);
        in alloyConfig;
      };

      systemd.services.alloy.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "alloy";
      };

      users.users.alloy = {
        isSystemUser = true;
        group = "users";
        extraGroups = [ "docker" ];
        createHome = false;
      };
      users.groups.alloy = { };
    }
  ]);
}

