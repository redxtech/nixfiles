{ config, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (cfgNet) address;
in {
  services.dashy = {
    enable = true;

    port = cfg.ports.dashy;

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
              url = "https://plex.${address}/web/index.html";
              description = "Media server";
            }
            {
              title = "Jellyseerr";
              icon =
                "https://raw.githubusercontent.com/Fallenbagel/jellyseerr/develop/public/os_icon.svg";
              url = "https://jellyseerr.${address}";
              description = "Request movies and tv shows";
            }
            {
              title = "Jellyfin";
              icon = "hl-jellyfin";
              url = "https://jellyfin.${address}";
              description = "Open source media server";
            }
            {
              title = "Jellyfin Vue";
              icon =
                "https://github.com/jellyfin/jellyfin-vue/blob/master/frontend/public/icon.png?raw=true";
              url = "https://jellyfin-vue.${address}";
              description = "Alternate jellyfin web ui";
            }
            {
              title = "Sonarr";
              icon = "hl-sonarr";
              url = "https://sonarr.${address}";
              description = "Automatically downloads tv shows";
            }
            {
              title = "Radarr";
              icon = "hl-radarr";
              url = "https://radarr.${address}";
              description = "Automatically downloads movies";
            }
            {
              title = "Prowlarr";
              icon = "hl-prowlarr";
              url = "https://prowlarr.${address}";
              description = "Automatically configures indexers for *arr apps";
            }
            {
              title = "Jackett";
              icon = "hl-jackett";
              url = "https://radarr.${address}";
              description = "Normalizes tracker searches for *arr apps";
            }
            {
              title = "Deluge";
              icon = "hl-deluge";
              url = "https://deluge.${address}";
              description = "Torrent client";
            }
            {
              title = "qBit";
              icon = "hl-qbittorrent";
              url = "https://qbit.${address}";
              description = "Torrent client";
            }
            {
              title = "Calibre";
              icon =
                "https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/calibre-icon.png";
              url = "https://calibre.${address}";
              description = "Powerful ebook software";
              statusCheckAcceptCodes = "401";
            }
            {
              title = "Calibre Web";
              icon =
                "https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/calibre-web-icon.png";
              url = "https://books.${address}";
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
              url = "https://dash.${address}";
              # icon = "hl-dashy"; # Broken for some reason
              icon =
                "https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/dashy.png";
              description = "This dashboard";
            }
            {
              title = "Cockpit";
              url = "https://cockpit.${address}";
              icon = "hl-cockpit";
              description = "Server management interface";
            }
            {
              title = "Portainer";
              url = "https://portainer.${address}";
              icon = "hl-portainer";
              description = "Docker management interface";
            }
            {
              title = "Startpage";
              url = "https://startpage.${address}";
              icon = "https://startpage.nas.gabedunn.dev/icon.svg";
              description = "Custom startpage";
            }
            {
              title = "Traefik";
              url = "https://traefik.${address}";
              icon = "hl-traefik";
              description = "Reverse proxy";
            }
            {
              title = "Adguard Home";
              url = "https://adguard.${address}";
              icon =
                "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/client/public/assets/favicon.png";
              description = "Network-wide, DNS level adblocking";
            }
            {
              title = "Flaresolverr";
              url = "https://flaresolverr.${address}";
              icon =
                "https://raw.githubusercontent.com/FlareSolverr/FlareSolverr/master/resources/flaresolverr_logo.png";
              description = "Cloudflare bypass";
            }
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
            # {
            #   title = "Home Assistant";
            #   url = "https://ha.${address}";
            #   icon = "hl-home-assistant";
            #   description = "Home automation";
            # }
            # {
            #   title = "Apprise";
            #   url = "https://apprise.${address}";
            #   icon =
            #     "https://github.com/caronc/apprise/blob/master/apprise/assets/themes/default/apprise-info-256x256.png?raw=true";
            #   description = "Notification service";
            # }
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
            {
              title = "Grafana";
              url = "https://grafana.${address}";
              icon = "hl-grafana";
            }
            {
              title = "Tautulli";
              url = "https://tautulli.${address}";
              icon = "hl-tautulli";
            }
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

