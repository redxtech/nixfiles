{ config, lib, pkgs, ... }:

let
  cfg = config.monitoring;
  inherit (cfg) ports;
  inherit (lib) mkIf mkOption mkEnableOption types;

  hostname = config.networking.hostName;
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
        };
      };

      # enable prometheus
      services.prometheus = {
        enable = true;
        port = ports.prometheus;
      };
    })

    {
      # enable grafana alloy on non-hosts
      services.alloy = {
        enable = true;

        extraFlags = [ "--server.http.listen-addr=0.0.0.0:${p ports.alloy}" ];

        configPath = let
          alloyConfig = pkgs.writeText "alloy-config.json"
            (builtins.concatStringsSep "\n" [''
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
              		url = "http://${grafanaHost}:${p ports.prometheus}/api/v1/write"
              	}
              }

              discovery.docker "${hostname}" {
              	host = "unix:///var/run/docker.sock"
              }
            '']);
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

