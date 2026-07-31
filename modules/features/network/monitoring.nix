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
        monitoringConfig = self.nixosConfigurations.${monitoringHost}.config;
        p = toString;

        mkScraper = name: address: ''
          prometheus.scrape "${name}" {
            targets    = [{ __address__ = "${address}" }]
            job_name   = "integrations/${name}"
            forward_to = [prometheus.relabel.filter_metrics.receiver]
          }
        '';
        mkLocalScraper = name: port: mkScraper name "127.0.0.1:${p port}";
        registeredScrapers = lib.mapAttrsToList mkLocalScraper cfg.scrapeTargets;
      in
      {
        options.monitoring = {
          isHost = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the system hosts the monitoring server.";
          };

          scrapeTargets = lib.mkOption {
            type = lib.types.attrsOf lib.types.port;
            default = { };
            description = "Local Prometheus scrape targets keyed by job name.";
          };
        };

        config = {
          network.services.alloy = 12346;

          services.alloy = {
            enable = true;
            extraFlags = [ "--server.http.listen-addr=0.0.0.0:12346" ];

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
                (builtins.concatStringsSep "\n" registeredScrapers)
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
                      url = "http://${monitoringHost}:${p monitoringConfig.services.prometheus.port}/api/v1/write"
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
                      url = "http://${monitoringHost}:${p monitoringConfig.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
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

  };
}
