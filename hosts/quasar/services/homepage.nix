{ config, lib, pkgs, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;
in {
  config = {
    network.services.home = cfg.ports.homepage;

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      listenPort = cfg.ports.homepage;

      allowedHosts = lib.concatStringsSep "," [
        "home.${cfgNet.address}"
        "quasar:${toString cfg.ports.homepage}"
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
                href = "https://plex.${cfgNet.address}";
                description = "plex media server";
                weight = -100;
                widget = {
                  type = "plex";
                  url = "https://plex.${cfgNet.address}";
                  key = "{{HOMEPAGE_VAR_PLEX}}";
                };
              };
            }
            {
              music = {
                icon = "navidrome.svg";
                href = "https://music.${cfgNet.address}";
                description = "music server";
                weight = -40;
                widget = {
                  type = "navidrome";
                  url = "https://music.${cfgNet.address}";
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
                href = "https://ha.${cfgNet.address}";
                description = "home automation";
                weight = -100;
                widget = {
                  type = "homeassistant";
                  url = "https://ha.${cfgNet.address}";
                  key = "{{HOMEPAGE_VAR_HOMEASSISTANT}}";
                };
              };
            }
            {
              esphome = {
                icon = "esphome.svg";
                href = "https://esphome.${cfgNet.address}";
                description = "esphome dashboard";
                weight = -90;
              };
            }
            {
              node-red = {
                icon = "node-red.svg";
                href = "https://node-red.${cfgNet.address}";
                description = "flow-based automation";
              };
            }
          ];
        }
        {
          admin = [{
            cockpit = {
              icon = "sh-cockpit.svg";
              href = "https://ha.${cfgNet.address}";
              description = "system control panel";
              weight = -100;
            };
          }];
        }
        {
          network = [
            {
              traefik = {
                icon = "traefik.svg";
                href = "https://traefik.${cfgNet.address}";
                description = "ingress controller";
                weight = -100;
                widget = {
                  type = "traefik";
                  url = "https://traefik.${cfgNet.address}";
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
                href = "https://grafana.${cfgNet.address}";
                description = "monitoring dashboard";
                weight = -100;
                widget = {
                  type = "grafana";
                  url = "https://grafana.${cfgNet.address}";
                  username = "{{HOMEPAGE_VAR_GRAFANA_USER}}";
                  password = "{{HOMEPAGE_VAR_GRAFANA_PASS}}";
                };
              };
            }
            {
              prometheus = {
                icon = "prometheus.svg";
                href = "https://prometheus.${cfgNet.address}";
                description = "metrics aggregator";
                weight = -90;
                widget = {
                  type = "prometheus";
                  url = "https://prometheus.${cfgNet.address}";
                };
              };
            }
            {
              "uptime kuma" = {
                icon = "uptime-kuma.svg";
                href = "https://uptime.${cfgNet.address}";
                description = "status page";
                weight = -80;
                widget = {
                  type = "uptimekuma";
                  url = "https://uptime.${cfgNet.address}";
                  slug = "main";
                };
              };
            }
            {
              "beszel" = {
                icon = "beszel.svg";
                href = "https://beszel.${cfgNet.address}";
                description = "docker monitoring";
                weight = -70;
                widget = {
                  type = "beszel";
                  url = "http://${cfg.hostname}:${toString cfg.ports.beszel}";
                  username = "{{HOMEPAGE_VAR_BESZEL_USER}}";
                  password = "{{HOMEPAGE_VAR_BESZEL_PASS}}";
                  systemId = "{{HOMEPAGE_VAR_BESZEL_SYSTEMID}}";
                  version = "2";
                };
              };
            }
            {
              loki = {
                icon = "loki.svg";
                href = "https://loki.${cfgNet.address}";
                description = "logs aggregator";
                weight = -60;
              };
            }
          ];
        }
        { arr = [ ]; }
        { download = [ ]; }
        { services = [ ]; }
        { utils = [ ]; }
      ];

      bookmarks = [{
        links = [{
          repo = [{
            abbr = "nf";
            href = "https://github.com/redxtech/nixfiles";
          }];
        }];
      }];

      environmentFile = config.sops.secrets.homepage_env.path;
    };

    environment.etc."homepage-dashboard/settings.yaml".text = lib.mkForce ''
      title: quasar
      startUrl: https://home.${cfgNet.address}
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

    sops.secrets.homepage_env.sopsFile = ../secrets.yaml;
  };
}
