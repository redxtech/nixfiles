{ lib, self, ... }:

{
  den.aspects.homepage.settings.secretsFile = self.lib.server.mkSecretsFileOption "Homepage";

  den.aspects.homepage.nixos =
    { config, host, ... }:
    let
      inherit (config.networking) fqdn;
      port = 8082;
    in
    {
      network.services.home = port;

      services.homepage-dashboard = {
        enable = true;
        openFirewall = true;
        listenPort = port;

        allowedHosts = lib.concatStringsSep "," [
          "home.${fqdn}"
          "quasar:${toString port}"
        ];

        docker.default = {
          host = "localhost";
          port = "2375";
        };

        widgets = [
          { logo.icon = "https://avatars.githubusercontent.com/u/18155001?v=4"; }
          {
            resources = {
              cpu = true;
              cputemp = true;
              memory = true;
              uptime = true;
              units = "metric";
            };
          }
          {
            datetime = {
              text_size = "xl";
              format = {
                timeStyle = "short";
                dateStyle = "short";
              };
            };
          }
        ];

        services = [
          {
            media = [
              {
                plex = {
                  icon = "plex.svg";
                  href = "https://plex.${fqdn}";
                  description = "plex media server";
                  weight = -100;
                  widget = {
                    type = "plex";
                    url = "https://plex.${fqdn}";
                    key = "{{HOMEPAGE_VAR_PLEX}}";
                  };
                };
              }
              {
                music = {
                  icon = "navidrome.svg";
                  href = "https://music.${fqdn}";
                  description = "music server";
                  weight = -40;
                  widget = {
                    type = "navidrome";
                    url = "https://music.${fqdn}";
                    user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                    token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                    salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                  };
                };
              }
            ];
          }
          {
            home = [
              {
                "home assistant" = {
                  icon = "home-assistant.svg";
                  href = "https://ha.${fqdn}";
                  description = "home automation";
                  weight = -100;
                  widget = {
                    type = "homeassistant";
                    url = "https://ha.${fqdn}";
                    key = "{{HOMEPAGE_VAR_HOMEASSISTANT}}";
                  };
                };
              }
              {
                esphome = {
                  icon = "esphome.svg";
                  href = "https://esphome.${fqdn}";
                  description = "esphome dashboard";
                  weight = -90;
                };
              }
              {
                node-red = {
                  icon = "node-red.svg";
                  href = "https://node-red.${fqdn}";
                  description = "flow-based automation";
                };
              }
            ];
          }
          {
            admin = [
              {
                cockpit = {
                  icon = "sh-cockpit.svg";
                  href = "https://cockpit.${fqdn}";
                  description = "system control panel";
                  weight = -100;
                };
              }
            ];
          }
          {
            network = [
              {
                traefik = {
                  icon = "traefik.svg";
                  href = "https://traefik.${fqdn}";
                  description = "ingress controller";
                  weight = -100;
                  widget = {
                    type = "traefik";
                    url = "https://traefik.${fqdn}";
                  };
                };
              }
              {
                "unifi controller" = {
                  icon = "unifi.svg";
                  href = "https://192.168.1.1";
                  description = "unifi network controller";
                  weight = -80;
                  widget = {
                    type = "unifi";
                    url = "https://192.168.1.1";
                    username = "{{HOMEPAGE_VAR_UNIFI_USER}}";
                    password = "{{HOMEPAGE_VAR_UNIFI_PASS}}";
                  };
                };
              }
            ];
          }
          {
            monitoring = [
              {
                grafana = {
                  icon = "grafana.svg";
                  href = "https://grafana.${fqdn}";
                  description = "monitoring dashboard";
                  weight = -100;
                  widget = {
                    type = "grafana";
                    url = "https://grafana.${fqdn}";
                    version = "2";
                    username = "{{HOMEPAGE_VAR_GRAFANA_USER}}";
                    password = "{{HOMEPAGE_VAR_GRAFANA_PASS}}";
                  };
                };
              }
              {
                prometheus = {
                  icon = "prometheus.svg";
                  href = "https://prometheus.${fqdn}";
                  description = "metrics aggregator";
                  weight = -90;
                  widget = {
                    type = "prometheus";
                    url = "https://prometheus.${fqdn}";
                  };
                };
              }
              {
                "uptime kuma" = {
                  icon = "uptime-kuma.svg";
                  href = "https://uptime.${fqdn}";
                  description = "status page";
                  weight = -80;
                  widget = {
                    type = "uptimekuma";
                    url = "https://uptime.${fqdn}";
                    slug = "main";
                  };
                };
              }
              {
                loki = {
                  icon = "loki.svg";
                  href = "https://loki.${fqdn}";
                  description = "logs aggregator";
                  weight = -60;
                };
              }
            ];
          }
          { arr = [ ]; }
          { books = [ ]; }
          { download = [ ]; }
          { services = [ ]; }
          { utils = [ ]; }
        ];

        bookmarks = [
          {
            links = [
              {
                repo = [
                  {
                    abbr = "nf";
                    href = "https://github.com/redxtech/nixfiles";
                  }
                ];
              }
            ];
          }
        ];

        environmentFiles = [ config.sops.secrets.homepage_env.path ];
      };

      environment.etc."homepage-dashboard/settings.yaml".text = lib.mkForce ''
        title: quasar
        startUrl: https://home.${fqdn}
        theme: dark
        color: slate
        iconStyle: theme
        headerStyle: boxedWidgets
        showStats: false
        cardBlur: sm
        layout:
          media:
            style: row
            columns: 4
            useEqualHeights: true
          home:
          books:
          admin:
          network:
          monitoring:
          download:
          services:
          utils:
          arr:
            style: row
            columns: 3
            useEqualHeights: true
      '';

      virtualisation.oci-containers.containers.docker-socket-proxy = {
        image = "ghcr.io/tecnativa/docker-socket-proxy:latest";
        environment = {
          CONTAINERS = "1";
          SERVICES = "1";
          TASKS = "1";
          POST = "0";
        };
        ports = [ "127.0.0.1:2375:2375" ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
      };

      sops.secrets.homepage_env.sopsFile = host.settings.homepage.secretsFile;
    };
}
