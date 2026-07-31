{
  den,
  self,
  lib,
  ...
}:

{
  den.aspects.monitoring = {
    includes = [ den.aspects.drishti ];

    nixos =
      { config, pkgs, ... }:
      let
        inherit (config.networking) hostName;

        cfg = config.monitoring;
        monitoringHost = lib.findFirst (
          host: self.nixosConfigurations.${host}.config.monitoring.isHost
        ) null (lib.attrNames self.nixosConfigurations);
        p = toString;

        mkScraper = name: address: ''
          prometheus.scrape "${name}" {
            targets    = [{ __address__ = "${address}" }]
            job_name   = "integrations/${name}"
            forward_to = [prometheus.relabel.filter_metrics.receiver]
          }
        '';
        mkLocalScraper = name: port: mkScraper name "127.0.0.1:${p port}";
        mkExportarr = name: port: mkLocalScraper "${name}_exportarr" port;
      in
      {
        options.monitoring = {
          isHost = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the system hosts the monitoring server.";
          };

          grafana_secret_key = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Grafana secret key.";
          };

          ports =
            lib.mapAttrs
              (
                _: default:
                lib.mkOption {
                  type = lib.types.port;
                  inherit default;
                  description = "Port used by this monitoring service.";
                }
              )
              {
                alloy = 12346;
                grafana = 3000;
                loki = 3002;
                prometheus = 3001;
              };
        };

        config = {
          network.services.alloy = cfg.ports.alloy;

          services.alloy = {
            enable = true;
            extraFlags = [ "--server.http.listen-addr=0.0.0.0:${p cfg.ports.alloy}" ];

            configPath = pkgs.writeText "alloy-config.alloy" (
              builtins.concatStringsSep "\n" [
                ''
                  prometheus.exporter.unix "${hostName}" { }

                  prometheus.scrape "scrape_metrics" {
                    targets         = prometheus.exporter.unix.${hostName}.targets
                    forward_to      = [prometheus.relabel.filter_metrics.receiver]
                    scrape_interval = "10s"
                  }

                  prometheus.scrape "${hostName}_docker" {
                    targets    = discovery.docker.${hostName}.targets
                    forward_to = [prometheus.relabel.filter_metrics.receiver]
                  }
                ''
                (mkLocalScraper "docker" 9323)
                (mkLocalScraper "traefik" config.network.finalServices.traefik)
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
                      url = "http://${monitoringHost}:${p cfg.ports.prometheus}/api/v1/write"
                    }
                  }
                ''
                ''
                  discovery.docker "${hostName}" {
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
                    sync_period = "5s"
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
                        "host" = "${hostName}",
                      }
                    }
                    forward_to = [loki.write.grafana_loki.receiver]
                  }
                ''
                ''
                  loki.source.docker "docker_logs" {
                    host       = "unix:///var/run/docker.sock"
                    targets    = discovery.docker.${hostName}.targets
                    labels     = {
                      "app"  = "docker",
                      "host" = "${hostName}",
                    }
                    forward_to    = [loki.write.grafana_loki.receiver]
                    relabel_rules = discovery.relabel.docker.rules
                  }

                  loki.source.journal "${hostName}_journal" {
                    forward_to    = [loki.write.grafana_loki.receiver]
                    relabel_rules = discovery.relabel.journal.rules
                    labels        = {
                      "app"  = "journal",
                      "host" = "${hostName}",
                    }
                  }
                ''
                ''
                  loki.write "grafana_loki" {
                    endpoint {
                      url = "http://${monitoringHost}:${p cfg.ports.loki}/loki/api/v1/push"
                    }
                  }
                ''
              ]
            );
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
        };
      };

    provides.server.nixos =
      { config, ... }:
      let
        cfg = config.monitoring;
        p = toString;
      in
      {
        monitoring.isHost = true;

        network.services = {
          inherit (cfg.ports)
            grafana
            loki
            prometheus
            ;
        };

        services = {
          grafana = {
            enable = true;
            settings = {
              auth.oauth_allow_insecure_email_lookup = true;
              security.secret_key = "$__file{${cfg.grafana_secret_key}}";

              server = {
                http_addr = "0.0.0.0";
                http_port = cfg.ports.grafana;
                domain = "grafana.${config.networking.fqdn}";
                root_url = "https://grafana.${config.networking.fqdn}";
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

          prometheus = {
            enable = true;
            port = cfg.ports.prometheus;
            extraFlags = [ "--web.enable-remote-write-receiver" ];
          };

          loki =
            let
              inherit (config.services.loki) dataDir;
            in
            {
              enable = true;
              configuration = {
                auth_enabled = false;
                server.http_listen_port = cfg.ports.loki;

                common = {
                  ring = {
                    instance_addr = "0.0.0.0";
                    kvstore.store = "inmemory";
                  };
                  replication_factor = 1;
                  path_prefix = "${dataDir}/loki";
                };

                schema_config.configs = [
                  {
                    from = "2024-06-01";
                    store = "tsdb";
                    object_store = "filesystem";
                    schema = "v13";
                    index = {
                      prefix = "index_";
                      period = "24h";
                    };
                  }
                ];

                storage_config.filesystem.directory = "${dataDir}/chunks";
              };

              extraFlags = [ "--server.http-listen-port=${p cfg.ports.loki}" ];
            };

          traefik.dynamicConfigOptions.http.routers.grafana.middlewares = [
            "homeassistant-allow-iframe"
          ];
        };

        sops.secrets =
          let
            mkSecret = {
              sopsFile = ../../../secrets/hosts/quasar/secrets.yaml;
              group = config.users.users.grafana.group;
              mode = "0440";
            };
          in
          {
            grafana_smtp_pw = mkSecret;
            grafana_smtp_user = mkSecret;
            grafana_smtp_host = mkSecret;
          };
      };
  };
}
