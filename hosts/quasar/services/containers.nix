{ config, pkgs, lib, self, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (cfgNet) address;

  inherit (self.lib.nas.paths cfg.paths) mkConf mkData mkDl downloads media;
  inherit (self.lib.containers) mkPort mkPorts;
  inherit (self.lib.containers.labels) mkHomepage;
  inherit (self.lib.containers.labels.traefik address)
    mkAllLabels mkAllLabelsPort mkTLRstr mkTLSstr mkTLHstr;

  defaultEnv = {
    PUID = toString config.users.users.${cfg.user}.uid;
    PGID = toString config.users.groups.${cfg.group}.gid;
    TZ = cfg.timezone;
  };

  mkExportarr = name: port: {
    image = "ghcr.io/onedr0p/exportarr:v2.0";
    cmd = [ name ];
    environment = defaultEnv // {
      PORT = toString port;
      URL = "https://${name}.${address}";
    };
    environmentFiles = [ config.sops.secrets."exportarr_${name}".path ];
    ports = [ (mkPorts port) ];
  };
in {
  network.services = { inherit (cfg.ports) lidarr radarr sonarr flood; };

  virtualisation.oci-containers = {
    containers = {
      actual = {
        image = "ghcr.io/actualbudget/actual:latest";
        labels = mkAllLabels "actual" {
          name = "actual";
          group = "utils";
          icon = "actual-budget.svg";
          href = "https://actual.${address}";
          desc = "actual budget";
        };
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.actual) ];
        volumes = [ (mkConf "actual") ];
      };

      apprise = {
        image = "lscr.io/linuxserver/apprise-api:latest";
        labels = mkAllLabels "apprise" {
          name = "apprise";
          group = "services";
          icon = "mdi-bullhorn";
          href = "https://apprise.${address}";
          desc = "notification service";
        };
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.apprise 8000) ];
        volumes = [ (mkConf "apprise") ];
      };

      bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        labels = mkAllLabels "bazarr" {
          name = "bazarr";
          group = "arr";
          icon = "bazarr.svg";
          href = "https://bazarr.${address}";
          desc = "subtitles downloader";
          weight = -90;
          widget = {
            type = "bazarr";
            url = "https://bazarr.${address}";
            key = "{{HOMEPAGE_VAR_BAZARR}}";
          };
        };
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.bazarr 6767) ];
        volumes = [ (mkConf "bazarr") media ];
      };

      beszel = {
        image = "henrygd/beszel:latest";
        labels = mkAllLabels "beszel" { };
        ports = [ (mkPorts cfg.ports.beszel) ];
        volumes = [ "${cfg.paths.config}/beszel:/beszel_data" ];
      };

      beszel-agent = {
        image = "henrygd/beszel-agent:latest";
        environment = {
          LISTEN = "/beszel_socket/beszel.sock";
          HUB_URL = "http://localhost:${toString cfg.ports.beszel}";
        };
        environmentFiles = [ config.sops.secrets."beszel_env".path ];
        volumes = [
          "${cfg.paths.config}/beszel-agent:/var/lib/beszel-agent"
          "${cfg.paths.config}/beszel-agent/beszel_socket:/beszel_socket"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        extraOptions = [ "--network" "host" ];
      };

      calibre = let
        mkHstr = header: "${mkTLHstr "calibre"}.customrequestheaders.${header}";
      in {
        image = "lscr.io/linuxserver/calibre:latest";
        labels = mkAllLabelsPort "calibre" cfg.ports.calibre-ssl {
          name = "calibre";
          group = "media";
          icon = "calibre.svg";
          href = "https://calibre.${address}";
          desc = "ebook manager";
        } // {
          "${mkTLSstr "calibre"}.loadbalancer.serverstransport" =
            "ignorecert@file";
          "${mkTLSstr "calibre"}.loadbalancer.server.scheme" = "https";
          "${mkTLRstr "calibre"}.middlewares" = "calibre@docker";
          "${mkHstr "Cross-Origin-Embedder-Policy"}" = "require-corp";
          "${mkHstr "Cross-Origin-Opener-Policy"}" = "same-origin";
          "${mkHstr "Cross-Origin-Resource-Policy"}" = "same-site";
        };
        environment = defaultEnv // {
          FILE__CUSTOM_USER = config.sops.secrets.calibre_user.path;
          FILE__PASSWORD = config.sops.secrets.calibre_pw.path;
          CUSTOM_PORT = "${toString cfg.ports.calibre}";
          CUSTOM_HTTPS_PORT = "${toString cfg.ports.calibre-ssl}";
        };
        ports = with cfg.ports; [
          (mkPorts calibre) # vnc
          (mkPorts calibre-ssl) # https vnc
          (mkPorts calibre-device) # device wireless connection
          (mkPort calibre-server 8081) # web server
        ];
        volumes = let
          secretPath = type: "${config.sops.secrets."calibre_${type}".path}";
          mkSecretMnt = type: "${secretPath type}:${secretPath type}";
        in [ (mkConf "calibre") (mkSecretMnt "user") (mkSecretMnt "pw") ];
      };

      calibre-web = {
        image = "crocodilestick/calibre-web-automated:latest";
        labels = mkAllLabels "books" {
          name = "calibre web";
          group = "media";
          icon = "calibre-web.svg";
          href = "https://books.${address}";
          desc = "ebook manager";
          weight = -50;
          widget = {
            type = "calibreweb";
            url = "https://books.${address}";
            username = "{{HOMEPAGE_VAR_CALIBREWEB_USERNAME}}";
            password = "{{HOMEPAGE_VAR_CALIBREWEB_PASSWORD}}";
          };
        } // {
          "${mkTLRstr "books"}.middlewares" = "homeassistant-allow-iframe@file";
        };
        environment = defaultEnv // {
          DOCKER_MODS =
            "linuxserver/mods:universal-calibre|linuxserver/mods:universal-package-install";
          INSTALL_PIP_PACKAGES = "jsonschema";
        };
        environmentFiles =
          [ config.sops.secrets.CALIBRE_WEB_HARDCOVER_KEY.path ];
        ports = [ (mkPorts cfg.ports.calibre-web) ];
        volumes = [
          (mkConf "calibre-web")
          (cfg.paths.config + "/calibre/Calibre Library:/calibre-library")
          (cfg.paths.config + "/calibre-web-ingest:/cwa-book-ingest")
        ];
      };

      ddclient = {
        image = "lscr.io/linuxserver/ddclient:latest";
        environment = defaultEnv;
        volumes = [
          "${config.sops.secrets."ddclient.conf".path}:/defaults/ddclient.conf"
        ];
      };

      espresense-companion = {
        image = "espresense/espresense-companion:latest";
        labels = mkAllLabels "espc" {
          name = "espresense companion";
          group = "home";
          icon = "https://avatars.githubusercontent.com/u/89139441?s=200&v=4";
          href = "https://espc.${address}";
          desc = "room presence ui";
          weight = -70;
        };
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.espresense-companion) (mkPorts 8268) ];
        volumes = [ "${(mkConf "espresense")}/espresense" ];
      };

      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        labels = mkAllLabels "flaresolverr" {
          name = "flaresolverr";
          group = "arr";
          icon = "flaresolverr.svg";
          href = "https://flaresolverr.${address}";
          desc = "cloudflare challenge resolver";
        };
        environment = defaultEnv // {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          CAPTCHA_SOLVER = "none";
        };
        ports = [ (mkPorts cfg.ports.flaresolverr) ];
      };

      ha-fusion = {
        image = "ghcr.io/matt8707/ha-fusion:latest";
        labels = mkAllLabels "fusion" {
          name = "ha fusion";
          group = "home";
          icon =
            "https://raw.githubusercontent.com/matt8707/addon-ha-fusion/refs/heads/main/icon.png";
          href = "https://fusion.${address}";
          desc = "home assistant dashboard";
        };
        environment = defaultEnv // { HASS_URL = "https://ha.${address}"; };
        volumes = [ "${cfg.paths.config}/ha-fusion:/app/data" ];
        ports = [ (mkPorts 5050) ];
      };

      jackett = {
        image = "lscr.io/linuxserver/jackett:latest";
        labels = mkAllLabels "jackett" {
          name = "jackett";
          group = "arr";
          icon = "jackett.svg";
          href = "https://jackett.${address}";
          desc = "arr indexer proxy";
        };
        environment = defaultEnv // { AUTO_UPDATE = "true"; };
        ports = [ (mkPort cfg.ports.jackett 9117) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      jdownloader = {
        image = "jlesage/jdownloader-2:latest";
        environment = defaultEnv // {
          USER_ID = toString config.users.users.${cfg.user}.uid;
          GROUP_ID = toString config.users.groups.${cfg.group}.gid;
          KEEP_APP_RUNNING = "1";
          # DARK_MODE = "1";
          WEB_LISTENING_PORT = "${toString cfg.ports.jdownloader}";
        };
        environmentFiles = [ config.sops.secrets."jdownloader_env".path ];
        ports = [ (mkPorts cfg.ports.jdownloader) ];
        volumes = [
          (mkConf "jdownloader")
          (cfg.paths.downloads + "/jdownloader:/output")
        ];
      };

      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        labels = mkAllLabelsPort "jellyfin" cfg.ports.jellyfin {
          name = "jellyfin";
          group = "media";
          icon = "jellyfin.svg";
          href = "https://jellyfin.${address}";
          desc = "media server";
          weight = -90;
          widget = {
            type = "jellyfin";
            url = "https://jellyfin.${address}";
            key = "{{HOMEPAGE_VAR_JELLYFIN}}";
            enableBlocks = "true";
            enableNowPlaying = "false";
          };
        };
        environment = defaultEnv // {
          JELLYFIN_PublishedServerUrl = "jellyfin.${address}";
          NVIDIA_VISIBLE_DEVICES = "all";
        };
        ports =
          [ (mkPorts cfg.ports.jellyfin) (mkPorts 8920) "${mkPorts 7359}/udp" ];
        volumes = [
          (mkConf "jellyfin")
          # "${cfg.paths.config}/jellyfin/custom-web:/usr/share/jellyfin/web"
          media
          (cfg.paths.config + "/calibre/Calibre Library:/books")
        ];
      };

      jellyfin-alt = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        labels = mkAllLabels "jellyfin-alt" {
          name = "jellyfin alt";
          group = "media";
          icon = "jellyfin.svg";
          href = "https://jellyfin-alt.${address}";
          desc = "media server";
          weight = -100;
        };
        environment = defaultEnv // {
          JELLYFIN_PublishedServerUrl = "jellyfin-alt.${address}";
          NVIDIA_VISIBLE_DEVICES = "all";
        };
        ports = [ (mkPort cfg.ports.jellyfin-alt 8096) ];
        volumes = [
          (mkConf "jellyfin-alt")
          (cfg.paths.downloads + "/qbit:/downloads")
        ];
      };

      jellyfin-vue = {
        image = "ghcr.io/jellyfin/jellyfin-vue:unstable";
        labels = mkAllLabels "jellyfin-vue" {
          name = "jellyfin vue";
          group = "media";
          icon =
            "https://raw.githubusercontent.com/jellyfin/jellyfin-vue/refs/heads/master/frontend/public/icon.svg";
          href = "https://jellyfin-vue.${address}";
          desc = "jellyfin web ui";
          weight = 9;
        };
        environment = {
          DEFAULT_SERVERS = "https://jellyfin.quasar.sucha.foo";
          HISTORY_ROUTER_MODE = "1";
        };
        ports = [ (mkPort cfg.ports.jellyfin-vue 80) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkAllLabelsPort "jellyseerr" cfg.ports.jellyseerr {
          name = "jellyseerr";
          group = "media";
          icon = "jellyseerr.svg";
          href = "https://jellyseerr.${address}";
          desc = "media request manager";
          weight = -60;
          widget = {
            type = "jellyseerr";
            url = "https://jellyseerr.${address}";
            key = "{{HOMEPAGE_VAR_JELLYSEERR}}";
          };
        };
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.jellyseerr 5055) ];
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
        extraOptions = [ "--network" "host" ];
      };

      kiwix = {
        image = "ghcr.io/kiwix/kiwix-serve:latest";
        labels = mkHomepage {
          name = "kiwix";
          group = "media";
          icon = "kiwix.svg";
          href = "http://quasar:${toString cfg.ports.kiwix}";
          desc = "offline encyclopedia";
        };
        volumes = [ (cfg.paths.downloads + "/deluge/zim:/data") ];
        ports = [ (mkPort cfg.ports.kiwix 8080) ];
        cmd = [
          "archlinux_en_all_maxi_2022-04.zim"
          "beer.stackexchange.com_en_all_2022-05.zim"
          "cooking.stackexchange.com_en_all_2022-05.zim"
          "cs.stackexchange.com_en_all_2021-04.zim"
          "developer.mozilla.org_en_all_2022-05.zim"
          "engineering.stackexchange.com_en_all_2022-05.zim"
          "explainxkcd_en_all_maxi_2021-03.zim"
          "the_infosphere_en_all_maxi_2022-01.zim"
          "movies.stackexchange.com_en_all_2022-05.zim"
          "musicfans.stackexchange.com_en_all_2022-05.zim"
          "openstreetmap-wiki_en_all_maxi_2021-03.zim"
          "programmers.stackexchange.com_en_all_2017-10.zim"
          "rationalwiki_en_all_maxi_2021-03.zim"
          "stackoverflow.com_en_all_2022-05.zim"
          "superuser.com_en_all_2022-05.zim"
          "sustainability.stackexchange.com_en_all_2022-05.zim"
          "unix.stackexchange.com_en_all_2022-05.zim"
          "vi.stackexchange.com_en_all_2022-05.zim"
          "wikibooks_en_all_maxi_2021-03.zim"
          "wikihow_en_maxi_2022-01.zim"
          "wikileaks_en_afghanistan-war-diary_2012-01.zim/wikileaks_en_afghanistan-war-diary_2012-01.zim"
          "wikipedia_en_all_maxi_2024-01.zim"
          "wikiquote_en_all_maxi_2022-05.zim"
          "wikisource_en_all_nopic_2022-05.zim"
          "wikisummaries_en_all_maxi_2021-04.zim"
          "wikiversity_en_all_maxi_2021-03.zim"
          "wikivoyage_en_all_maxi_2022-06.zim"
          "wiktionary_en_all_maxi_2022-02.zim"
        ];
      };

      koinsight = {
        image = "ghcr.io/georgesg/koinsight:latest";
        labels = mkAllLabels "koinsight" {
          group = "media";
          icon = "mdi-book-information-variant";
          name = "koinsight";
          href = "https://koinsight.${address}";
          desc = "reading metrics";
          weight = -60;
        };
        ports = [ (mkPort cfg.ports.koinsights 3000) ];
        volumes = [ (cfg.paths.config + "/koinsight:/app/data") ];
      };

      ladder = {
        image = "wasimaster/13ft:latest";
        labels = mkAllLabels "ladder" {
          name = "13ft ladder";
          group = "utils";
          icon = "mdi-ladder";
          href = "https://ladder.${address}";
          desc = "home assistant dashboard";
        };
        ports = [ (mkPort cfg.ports.ladder 5000) ];
      };

      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        labels = mkHomepage {
          name = "lidarr";
          group = "arr";
          icon = "lidarr.svg";
          href = "https://lidarr.${address}";
          desc = "music downloader";
          weight = -100;
          widget = {
            type = "lidarr";
            url = "https://lidarr.${address}";
            key = "{{HOMEPAGE_VAR_LIDARR}}";
          };
        };
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.lidarr) ];
        volumes = [ (mkConf "lidarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      n8n = {
        image = "docker.n8n.io/n8nio/n8n:latest";
        # user = "${cfg.user}:${cfg.group}";
        labels = mkAllLabels "n8n" {
          name = "n8n";
          group = "utils";
          icon = "n8n.svg";
          href = "https://n8n.${address}";
          desc = "workflow automation";
          weight = -90;
        };
        environment = defaultEnv // {
          WEBHOOK_URL = "https://n8n.${address}";
          N8N_PORT = toString cfg.ports.n8n;
          N8N_DATA_TABLES_MAX_SIZE_BYTES = "1073741824";
        };
        volumes = [ "${cfg.paths.config}/n8n:/home/node/.n8n" ];
      };

      paperless = {
        image = "lscr.io/linuxserver/paperless-ngx:latest";
        labels = mkAllLabels "docs" {
          name = "paperless";
          group = "media";
          icon = "paperless.svg";
          href = "https://docs.${address}";
          desc = "document management";
          weight = -30;
          widget = {
            type = "paperlessngx";
            url = "https://docs.${address}";
            username = "{{HOMEPAGE_VAR_PAPERLESS_USER}}";
            password = "{{HOMEPAGE_VAR_PAPERLESS_PASS}}";
          };
        };
        environment = defaultEnv // {
          PAPERLESS_URL = "https://docs.${cfgNet.address}";
        };
        ports = [ (mkPort cfg.ports.paperless 8000) ];
        volumes = [ (mkConf "paperless") (mkData "paperless") ];
      };

      portainer = {
        # set options not covered by base module
        ports = lib.mkForce [ "8000:8000" (mkPort cfg.ports.portainer 9000) ];
        volumes = lib.mkForce [
          "/var/run/docker.sock:/var/run/docker.sock"
          (mkData "portainer")
        ];
      };

      portainer-agent = {
        ports = lib.mkForce [ (mkPort cfg.ports.portainer-agent 9001) ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        labels = mkAllLabelsPort "prowlarr" cfg.ports.prowlarr {
          name = "prowlarr";
          group = "arr";
          icon = "prowlarr.svg";
          href = "https://prowlarr.${address}";
          desc = "arr indexer proxy";
          weight = -80;
          widget = {
            type = "prowlarr";
            url = "https://prowlarr.${address}";
            key = "{{HOMEPAGE_VAR_PROWLARR}}";
          };
        };
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.prowlarr 9696) ];
        volumes = [ (mkConf "prowlarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      qbit = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        labels = mkAllLabelsPort "torrent" cfg.ports.qbit {
          name = "qbit";
          group = "download";
          icon = "qbittorrent.svg";
          href = "https://torrent.${address}";
          desc = "torrent client";
          widget = {
            type = "qbittorrent";
            url = "https://torrent.${address}";
            username = "{{HOMEPAGE_VAR_QBIT_USER}}";
            password = "{{HOMEPAGE_VAR_QBIT_PASS}}";
          };
        };
        environment = defaultEnv // {
          WEBUI_PORT = toString cfg.ports.qbit;
          TORRENTING_PORT = toString cfg.ports.qbit-torrent;
        };
        ports = [
          (mkPorts cfg.ports.qbit)
          (mkPorts cfg.ports.qbit-torrent)
          "${mkPorts cfg.ports.qbit-torrent}/udp"
        ];
        volumes = [
          (mkConf "qbit")
          (cfg.paths.downloads + "/deluge:/downloads")
          "${pkgs.vuetorrent}/share/vuetorrent:/vuetorrent:ro"
        ];
      };

      qbit-alt = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        labels = mkAllLabelsPort "qbit" cfg.ports.qbit-alt {
          name = "qbit alt";
          group = "download";
          icon = "qbittorrent.svg";
          href = "https://qbit.${address}";
          desc = "alternate torrent client";
          widget = {
            type = "qbittorrent";
            url = "https://qbit.${address}";
            username = "{{HOMEPAGE_VAR_QBIT_ALT_USER}}";
            password = "{{HOMEPAGE_VAR_QBIT_ALT_PASS}}";
          };
        };
        environment = defaultEnv // {
          WEBUI_PORT = toString cfg.ports.qbit-alt;
          TORRENTING_PORT = toString cfg.ports.qbit-alt-torrent;
        };
        ports = [
          (mkPorts cfg.ports.qbit-alt)
          (mkPorts cfg.ports.qbit-alt-torrent)
          "${mkPorts cfg.ports.qbit-alt-torrent}/udp"
        ];
        volumes = [
          (mkConf "qbit-alt")
          (cfg.paths.downloads + "/qbit:/downloads")
          "${pkgs.vuetorrent}/share/vuetorrent:/vuetorrent:ro"
        ];
      };

      qdirstat = {
        image = "lscr.io/linuxserver/qdirstat:latest";
        environment = defaultEnv // {
          FILE__CUSTOM_USER = config.sops.secrets.qdirstat_user.path;
          FILE__PASSWORD = config.sops.secrets.qdirstat_pw.path;
          CUSTOM_PORT = "${toString cfg.ports.qdirstat}";
        };
        labels = mkAllLabelsPort "qdirstat" cfg.ports.qdirstat {
          name = "qdirstat";
          group = "utils";
          icon = "qdirstat.svg";
          href = "https://qdirstat.${address}";
          desc = "disk usage statistics";
        };
        ports = [ (mkPorts cfg.ports.qdirstat) ];
        volumes = let
          secretPath = type: "${config.sops.secrets."qdirstat_${type}".path}";
          mkSecretMnt = type: "${secretPath type}:${secretPath type}";
        in [
          (mkConf "qdirstat")
          (mkSecretMnt "user")
          (mkSecretMnt "pw")
          "/:/data:ro"
        ];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        labels = mkHomepage {
          name = "radarr";
          group = "media";
          icon = "radarr.svg";
          href = "https://radarr.${address}";
          desc = "movie downloader";
          weight = -70;
          widget = {
            type = "radarr";
            url = "https://radarr.${address}";
            key = "{{HOMEPAGE_VAR_RADARR}}";
          };
        };
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.radarr 7878) ];
        volumes = [ (mkConf "radarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      radarr-exportarr = mkExportarr "radarr" 9708;

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = defaultEnv;
        labels = mkHomepage {
          name = "sonarr";
          group = "media";
          icon = "sonarr.svg";
          href = "https://sonarr.${address}";
          desc = "tv downloader";
          weight = -80;
          widget = {
            type = "sonarr";
            url = "https://sonarr.${address}";
            key = "{{HOMEPAGE_VAR_SONARR}}";
          };
        };
        ports = [ (mkPort cfg.ports.sonarr 8989) ];
        volumes = [ (mkConf "sonarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      sonarr-exportarr = mkExportarr "sonarr" 9707;

      signaturepdf = {
        image = "ghcr.io/redxtech/signaturepdf:master";
        labels = mkAllLabels "pdf" {
          name = "pdf";
          group = "utils";
          icon = "mdi-signature";
          href = "https://pdf.${address}";
          desc = "pdf signing and other tools";
        };
        environment = defaultEnv // {
          SERVERNAME = "pdf.${cfgNet.address}";
          UPLOAD_MAX_FILESIZE = "64M";
          POST_MAX_SIZE = "64M";
          DEFAULT_LANGUAGE = "en_CA.UTF-8";
          PDF_STORAGE_ENCRYPTION = "true";
        };
        ports = [ (mkPort cfg.ports.pdf 80) ];
        volumes = [ (mkData "pdf") ];
      };

      syncthing = {
        image = "lscr.io/linuxserver/syncthing:latest";
        environment = defaultEnv;
        labels = mkAllLabelsPort "syncthing" cfg.ports.syncthing {
          name = "syncthing";
          group = "services";
          icon = "syncthing.svg";
          href = "https://syncthing.${address}";
          desc = "file syncing";
        };
        ports = [
          (mkPorts cfg.ports.syncthing)
          "22000:22000/tcp"
          "22000:22000/udp"
          "21027:21027/udp"
        ];
        volumes = [ (mkConf "syncthing") (mkData "syncthing") ];
      };

      tautulli = {
        image = "lscr.io/linuxserver/tautulli:latest";
        labels = mkAllLabels "tautulli" {
          name = "tautulli";
          group = "monitoring";
          icon = "tautulli.svg";
          href = "https://tautulli.${address}";
          desc = "plex stats page";
        };
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.tautulli) ];
        volumes = [
          (mkConf "tautulli")
          "${cfg.paths.config}/plex/Plex Media Server/Logs:/Logs"
        ];
      };

      unpoller = {
        image = "ghcr.io/unpoller/unpoller:latest";
        labels = mkAllLabels "unpoller" {
          name = "unpoller";
          group = "services";
          icon = "https://i.imgur.com/VBHV26V.png";
          href = "https://unpoller.${address}";
          desc = "unifi device poller";
        };
        environment = defaultEnv // {
          UP_UNIFI_DEFAULT_URL = "https://unifi";
          UP_INFLUXDB_DISABLE = "true";
          UP_UNIFI_DEFAULT_SAVE_DPI = "true";
        };
        environmentFiles = [ config.sops.secrets."unpoller.env".path ];
        ports = [ (mkPorts cfg.ports.unpoller) ];
        volumes = [ (mkConf "unpoller") ];
      };

      watchtower = {
        image = "containrrr/watchtower:latest";
        labels = mkAllLabels "watchtower" {
          name = "watchtower";
          group = "services";
          icon = "watchtower.svg";
          href = "https://watchtower.${address}";
          desc = "docker container updating";
          weight = -100;
          widget = {
            type = "watchtower";
            url = "https://watchtower.${address}";
            key = "{{HOMEPAGE_VAR_WATCHTOWER}}";
          };
        };
        environment = defaultEnv // { WATCHTOWER_HTTP_API_METRICS = "true"; };
        environmentFiles = [ config.sops.secrets."watchtower_env".path ];
        ports = [ (mkPort cfg.ports.watchtower 8080) ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };

      # invoice ninja
      # wireguard
      # tubearchivist
      # duplicati/duplicacy
    };
  };

  system.activationScripts.mkDockerNetworks = let networks = [ "paperless" ];
  in ''
    # gracefully exit if docker isn't running
    ${pkgs.docker}/bin/docker ps >/dev/null 2>&1 || (echo "docker is not running" && return)

    for network in ${toString networks}; do
      ${pkgs.docker}/bin/docker network inspect $network >/dev/null 2>&1 ||
        ${pkgs.docker}/bin/docker network create --driver bridge $network
    done
  '';

  networking.firewall.allowedTCPPorts = with cfg.ports; [ calibre-device ];

  sops.secrets = {
    "ddclient.conf".sopsFile = ../secrets.yaml;
    beszel_env.sopsFile = ../secrets.yaml;
    CALIBRE_WEB_HARDCOVER_KEY.sopsFile = ../secrets.yaml;
    calibre_user.sopsFile = ../secrets.yaml;
    calibre_pw.sopsFile = ../secrets.yaml;
    exportarr_sonarr.sopsFile = ../secrets.yaml;
    exportarr_radarr.sopsFile = ../secrets.yaml;
    jdownloader_env.sopsFile = ../secrets.yaml;
    qdirstat_user.sopsFile = ../secrets.yaml;
    qdirstat_pw.sopsFile = ../secrets.yaml;
    "unpoller.env".sopsFile = ../secrets.yaml;
    watchtower_env.sopsFile = ../secrets.yaml;
  };
}

