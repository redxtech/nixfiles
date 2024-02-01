{ config, pkgs, ... }:

let cfg = config.nas;
in {
  services.dashy = {
    enable = true;
    # package = pkgs.dashy.override { nodejs-16_x = pkgs.nodejs_18; };

    port = cfg.ports.dashy;
    user = cfg.user;
    group = cfg.group;
    dataDir = cfg.paths.data + "/dashy";
    mutableConfig = false;

    settings = {
      pageInfo = {
        title = "Quasar Dashboard";
        description = "Nyaa~~";
        navLinks = [
          {
            title = "github";
            path = "https://github.com/redxtech";
          }
          {
            title = "nixfiles";
            path = "https://github.com/redxtech/nixfiles";
          }
        ];
      };
      appConfig = {
        theme = "dracula";
        layout = "auto";
        iconSize = "large";
        language = "en";
        statusCheck = true;
        statusCheckInterval = 60;
        # hideComponents.hideSettings = true;
        webSearch = {
          searchEngine = "custom";
          customSearchEngine = "https://kagi.com/search?q=";
        };
      };
      sections = [
        {
          name = "Media";
          icon = "fad fa-photo-video";
          displayData = {
            sortBy = "default";
            rows = 1;
            cols = 1;
            collapsed = false;
            hideForGuests = false;
          };
          items = [
            {
              title = "Plex";
              icon = "hl-plex";
              url = "https://plex.${cfg.domain}/web/index.html";
              description = "Media server";
            }
            # {
            #   title = "Jellyfin";
            #   icon = "hl-jellyfin";
            #   url = "https://jellyfin.${cfg.domain}";
            #   description = "Open source media server";
            # }
            {
              title = "Sonarr";
              icon = "hl-sonarr";
              url = "https://sonarr.${cfg.domain}";
              description = "Automatically downloads tv shows";
            }
            {
              title = "Radarr";
              icon = "hl-radarr";
              url = "https://radarr.${cfg.domain}";
              description = "Automatically downloads movies";
            }
            {
              title = "Jackett";
              icon = "hl-jackett";
              url = "https://radarr.${cfg.domain}";
              description = "Normalizes tracker searches for *arr apps";
            }
            {
              title = "Deluge";
              icon = "hl-deluge";
              url = "https://deluge.${cfg.domain}";
              description = "Torrent client";
            }
            # {
            #   title = "Kiwix";
            #   icon = "hl-kiwix-light";
            #   url = "https://wiki.${cfg.domain}";
            #   description = "Self-hosted wiki";
            # }
            {
              title = "Calibre";
              icon = "hl-calibre";
              url = "https://calibre.${cfg.domain}";
              description = "Powerful ebook software";
            }
            {
              title = "Calibre Web";
              icon = "hl-calibre";
              url = "https://calibre-web.${cfg.domain}";
              description = "Calibre web interface";
            }
          ];
        }
        {
          name = "Admin";
          icon = "fad fa-user-crown";
          displayData = {
            sortBy = "default";
            rows = 1;
            cols = 1;
            collapsed = false;
            hideForGuests = true;
          };
          items = [
            {
              title = "Dashy";
              url = "https://dash.${cfg.domain}";
              # icon = "hl-dashy"; # Broken for some reason
              icon =
                "https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/dashy.png";
              description = "This dashboard";
            }
            {
              title = "Cockpit";
              url = "https://${cfg.domain}";
              icon = "hl-cockpit";
              description = "Server management interface";
            }
            {
              title = "Traefik";
              url = "http://quasar:8080";
              icon = "hl-traefik";
              description = "Reverse proxy";
            }
            {
              title = "Adguard Home";
              url = "https://adguard.${cfg.domain}";
              icon = "hl-adguard-home";
              description = "Network-wide, DNS level adblocking";
            }
            # rec {
            #   title = "Nix cache";
            #   url = "https://cache.${cfg.domain}";
            #   statusCheckUrl = "${url}/nix-cache-info";
            #   icon =
            #     "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake.svg";
            # }
          ];
        }
        {
          name = "Productivity";
          icon = "fad fa-bookmark";
          displayData = {
            sortBy = "default";
            rows = 1;
            cols = 1;
            collapsed = false;
            hideForGuests = false;
          };
          items = [
            {
              title = "Monica";
              url = "https://monica.${cfg.domain}";
              icon = "hl-monica";
              description = "Personal CRM";
            }
            {
              title = "Apprise";
              url = "https://apprise.${cfg.domain}";
              icon = "hl-apprise";
              description = "Notification service";
            }
            {
              title = "Grocy";
              url = "https://grocy.${cfg.domain}";
              icon = "hl-grocy";
              description = "ERP - beyond the fridge";
            }
            {
              title = "NextCloud";
              url = "https://cloud.${cfg.domain}";
              icon = "hl-hextcloud";
              description = "Cloud";
            }
            {
              title = "Home Assistant";
              url = "https://ha.${cfg.domain}";
              icon = "hl-home-assistant";
              description = "Home automation";
            }
          ];
        }
        {
          name = "Monitoring";
          icon = "fad fa-analytics";
          displayData = {
            sortBy = "default";
            rows = 1;
            cols = 1;
            collapsed = false;
            hideForGuests = true;
          };
          items = [
            # {
            #   title = "Netdata";
            #   url = "https://netdata.${cfg.domain}";
            #   icon = "hl-netdata";
            # }
            {
              title = "Tautulli";
              url = "https://tautulli.${cfg.domain}";
              icon = "hl-tautulli";
            }
            # {
            #   title = "Grafana";
            #   url = "https://grafana.${cfg.domain}";
            #   icon = "hl-grafana";
            # }
          ];
        }
      ];
    };
  };
}

