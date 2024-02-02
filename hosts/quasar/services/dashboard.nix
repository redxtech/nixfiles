{ config, pkgs, ... }:

let cfg = config.nas;
in {
  services.dashy = {
    enable = true;
    # package = pkgs.dashy.override { nodejs-16_x = pkgs.nodejs_18; };

    port = cfg.ports.dashy;
    mutableConfig = false;

    settings = {
      pageInfo = {
        title = "quasar dashboard";
        description = "shut up baby, i know it";
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
            {
              title = "Jellyseerr";
              icon =
                "https://raw.githubusercontent.com/Fallenbagel/jellyseerr/develop/public/os_icon.svg";
              url = "https://jellyseerr.${cfg.domain}";
              description = "Request movies and tv shows";
            }
            {
              title = "Jellyfin";
              icon = "hl-jellyfin";
              url = "https://jellyfin.${cfg.domain}";
              description = "Open source media server";
            }
            {
              title = "Jellyfin Vue";
              icon =
                "https://github.com/jellyfin/jellyfin-vue/blob/master/frontend/public/icon.png?raw=true";
              url = "https://jellyfin-vue.${cfg.domain}";
              description = "Alternate jellyfin web ui";
            }
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
              title = "Prowlarr";
              icon = "hl-prowlarr";
              url = "https://prowlarr.${cfg.domain}";
              description = "Automatically configures indexers for *arr apps";
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
            {
              title = "qBit";
              icon = "hl-qbittorrent";
              url = "https://qbit.${cfg.domain}";
              description = "Torrent client";
            }
            {
              title = "Calibre";
              icon =
                "https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/calibre-icon.png";
              url = "https://calibre.${cfg.domain}";
              description = "Powerful ebook software";
              statusCheckAcceptCodes = "401";
            }
            {
              title = "Calibre Web";
              icon =
                "https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/calibre-web-icon.png";
              url = "https://calibre-web.${cfg.domain}";
              description = "Calibre web interface";
            }
            {
              title = "Kiwix";
              icon =
                "https://github.com/kiwix/kiwix-js-pwa/blob/main/www/img/Kiwix_icon_transparent_600x600.png?raw=true";
              url = "http://quasar:${toString cfg.ports.kiwix}";
              description = "Self-hosted wiki";
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
              title = "Portainer";
              url = "http://quasar:9000";
              icon = "hl-portainer";
              description = "Docker management interface";
            }
            {
              title = "Startpage";
              url = "https://startpage.${cfg.domain}";
              icon = "https://startpage.nas.gabedunn.dev/icon.svg";
              description = "Custom startpage";
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
              icon =
                "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/client/public/assets/favicon.png";
              description = "Network-wide, DNS level adblocking";
            }
            {
              title = "Flaresolverr";
              url = "https://Flaresolverr.${cfg.domain}";
              icon =
                "https://raw.githubusercontent.com/FlareSolverr/FlareSolverr/master/resources/flaresolverr_logo.png";
              description = "Cloudflare bypass";
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
              title = "NextCloud";
              url = "https://cloud.${cfg.domain}";
              icon =
                "https://raw.githubusercontent.com/nextcloud/server/master/core/img/favicon.svg";
              description = "Cloud";
            }
            {
              title = "Grocy";
              url = "https://grocy.${cfg.domain}";
              icon = "hl-grocy";
              description = "ERP - beyond the fridge";
            }
            {
              title = "Home Assistant";
              url = "https://ha.${cfg.domain}";
              icon = "hl-home-assistant";
              description = "Home automation";
            }
            {
              title = "Apprise";
              url = "https://apprise.${cfg.domain}";
              icon =
                "https://github.com/caronc/apprise/blob/master/apprise/assets/themes/default/apprise-info-256x256.png?raw=true";
              description = "Notification service";
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
            {
              title = "qDirStat";
              url = "http://quasar:${toString cfg.ports.qdirstat}";
              icon =
                "https://raw.githubusercontent.com/shundhammer/qdirstat/master/src/icons/qdirstat.svg";
              description = "Disk usage statistics";
            }
          ];
        }
      ];
    };
  };
}

