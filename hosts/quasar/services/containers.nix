{ config, pkgs, lib, self, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (cfgNet) address;

  defaultEnv = {
    PUID = toString config.users.users.${cfg.user}.uid;
    PGID = toString config.users.groups.${cfg.group}.gid;
    TZ = cfg.timezone;
  };

  paths = self.lib.nas.paths cfg.paths;
  inherit (paths) mkConf mkData mkDl downloads media;

  mkPort = host: guest: "${toString host}:${toString guest}";
  mkPorts = port: "${toString port}:${toString port}";
  mkTLstr = name: type: "traefik.http.${type}.${name}"; # make traefik label
  mkTLRstr = name: "${mkTLstr name "routers"}"; # make traefik router label
  mkTLSstr = name: "${mkTLstr name "services"}"; # make traefik router label
  mkTLHstr = name: "${mkTLstr name "middlewares"}.headers"; # middleware label
  mkLabels = name: {
    "traefik.enable" = "true";
    "${mkTLRstr name}.rule" = "Host(`${name}.${cfgNet.address}`)";
    "${mkTLRstr name}.entrypoints" = "websecure";
    "${mkTLRstr name}.tls" = "true";
    "${mkTLRstr name}.tls.certresolver" = "cloudflare";
  };
  mkLabelsPort = name: port:
    (mkLabels name) // {
      "${mkTLSstr name}.loadbalancer.server.port" = "${toString port}";
    };

  mkHomepage = self.lib.containers.labels.mkHomepage;

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
  virtualisation.oci-containers = {
    containers = {
      apprise = {
        image = "lscr.io/linuxserver/apprise-api:latest";
        ports = [ (mkPort cfg.ports.apprise 8000) ];
        labels = mkLabels "apprise";
        environment = defaultEnv;
        volumes = [ (mkConf "apprise") ];
      };

      bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        labels = mkLabels "bazarr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.bazarr 6767) ];
        volumes = [ (mkConf "bazarr") media ];
      };

      calibre = let
        mkHstr = header: "${mkTLHstr "calibre"}.customrequestheaders.${header}";
      in {
        image = "lscr.io/linuxserver/calibre:latest";
        labels = (mkLabelsPort "calibre" cfg.ports.calibre-ssl) // {
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
        ports = [
          (mkPorts cfg.ports.calibre) # vnc
          (mkPorts cfg.ports.calibre-ssl) # https vnc
          (mkPort cfg.ports.calibre-server 8081) # web server
          (mkPorts 8808) # device wireless connection
        ];
        volumes = let
          secretPath = type: "${config.sops.secrets."calibre_${type}".path}";
          mkSecretMnt = type: "${secretPath type}:${secretPath type}";
        in [ (mkConf "calibre") (mkSecretMnt "user") (mkSecretMnt "pw") ];
      };

      calibre-web = {
        image = "lscr.io/linuxserver/calibre-web:latest";
        labels = mkLabels "books" // {
          "${mkTLRstr "books"}.middlewares" = "homeassistant-allow-iframe@file";
        };
        environment = defaultEnv // {
          DOCKER_MODS = "linuxserver/mods:universal-calibre";
        };
        ports = [ (mkPort cfg.ports.calibre-web 8083) ];
        volumes = [
          (mkConf "calibre-web")
          (cfg.paths.config + "/calibre/Calibre Library:/books")
        ];
      };

      ddclient = {
        image = "lscr.io/linuxserver/ddclient:latest";
        environment = defaultEnv;
        volumes = [
          "${config.sops.secrets."ddclient.conf".path}:/defaults/ddclient.conf"
        ];
      };

      deluge = {
        image = "lscr.io/linuxserver/deluge:latest";
        labels = mkLabelsPort "deluge" cfg.ports.deluge;
        ports = [
          (mkPorts cfg.ports.deluge)
          "6881:6881"
          "6881:6881/udp"
          "58846:58846"
        ];
        environment = defaultEnv;
        volumes = [ (mkConf "deluge") (mkDl "deluge") ];
      };

      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        labels = mkLabels "flaresolverr";
        environment = defaultEnv // {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          CAPTCHA_SOLVER = "none";
        };
        ports = [ (mkPorts cfg.ports.flaresolverr) ];
      };

      grocy = {
        image = "lscr.io/linuxserver/grocy:latest";
        labels = mkLabels "grocy";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.grocy 80) ];
        volumes = [ (mkConf "grocy") ];
      };

      ha-fusion = {
        image = "ghcr.io/matt8707/ha-fusion:latest";
        labels = mkLabels "fusion";
        environment = defaultEnv // { HASS_URL = "https://ha.${address}"; };
        volumes = [ "${cfg.paths.config}/ha-fusion:/app/data" ];
        ports = [ (mkPorts 5050) ];
      };

      jackett = {
        image = "lscr.io/linuxserver/jackett:latest";
        labels = mkLabels "jackett";
        environment = defaultEnv // { AUTO_UPDATE = "true"; };
        ports = [ (mkPort cfg.ports.jackett 9117) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        labels = mkLabelsPort "jellyfin" cfg.ports.jellyfin;
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

      jellyfin-vue = {
        image = "ghcr.io/jellyfin/jellyfin-vue:unstable";
        labels = mkLabels "jellyfin-vue";
        environment = {
          DEFAULT_SERVERS = "https://jellyfin.quasar.sucha.foo";
          HISTORY_ROUTER_MODE = "1";
        };
        ports = [ (mkPort cfg.ports.jellyfin-vue 80) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkLabelsPort "jellyseerr" cfg.ports.jellyseerr;
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.jellyseerr 5055) ];
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
        extraOptions = [ "--network" "host" ];
      };

      kiwix = {
        image = "ghcr.io/kiwix/kiwix-serve:latest";
        # labels = mkLabelsPort "wiki" cfg.ports.kiwix;
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

      ladder = {
        image = "wasimaster/13ft:latest";
        labels = mkLabels "ladder";
        ports = [ (mkPort cfg.ports.ladder 5000) ];
      };

      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.lidarr) ];
        volumes = [ (mkConf "lidarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      paperless = {
        image = "lscr.io/linuxserver/paperless-ngx:latest";
        labels = mkLabels "docs";
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
        labels = mkLabelsPort "prowlarr" cfg.ports.prowlarr;
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.prowlarr 9696) ];
        volumes = [ (mkConf "prowlarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      qbit = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        labels = mkLabelsPort "qbit" cfg.ports.qbit;
        environment = defaultEnv // {
          WEBUI_PORT = "${toString cfg.ports.qbit}";
        };
        ports = [ (mkPorts cfg.ports.qbit) "6882:6882" "6882:6882/udp" ];
        volumes = [
          (mkConf "qbit")
          (mkData "qbit")
          (cfg.paths.downloads + "/qbit:/downloads")
          "${pkgs.vuetorrent}/var/www/vuetorrent:/vuetorrent:ro"
        ];
      };

      qdirstat = {
        image = "lscr.io/linuxserver/qdirstat:latest";
        environment = defaultEnv // {
          FILE__CUSTOM_USER = config.sops.secrets.qdirstat_user.path;
          FILE__PASSWORD = config.sops.secrets.qdirstat_pw.path;
          CUSTOM_PORT = "${toString cfg.ports.qdirstat}";
        };
        # labels = (mkLabelsPort "qdirstat" cfg.ports.qdirstat);
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
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.radarr 7878) ];
        volumes = [ (mkConf "radarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      radarr-exportarr = mkExportarr "radarr" 9708;

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.sonarr 8989) ];
        volumes = [ (mkConf "sonarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      sonarr-exportarr = mkExportarr "sonarr" 9707;

      signaturepdf = {
        image = "ghcr.io/redxtech/signaturepdf:master";
        labels = mkLabels "pdf";
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
        labels = mkLabelsPort "syncthing" cfg.ports.syncthing;
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
        labels = mkLabels "tautulli";
        environment = defaultEnv;
        ports = [ (mkPorts cfg.ports.tautulli) ];
        volumes = [
          (mkConf "tautulli")
          "${cfg.paths.config}/plex/Plex Media Server/Logs:/Logs"
        ];
      };

      unpoller = {
        image = "ghcr.io/unpoller/unpoller:latest";
        labels = mkLabels "unpoller";
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
        environment = defaultEnv;
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
  sops.secrets = {
    "ddclient.conf".sopsFile = ../secrets.yaml;
    calibre_user.sopsFile = ../secrets.yaml;
    calibre_pw.sopsFile = ../secrets.yaml;
    exportarr_sonarr.sopsFile = ../secrets.yaml;
    exportarr_radarr.sopsFile = ../secrets.yaml;
    qdirstat_user.sopsFile = ../secrets.yaml;
    qdirstat_pw.sopsFile = ../secrets.yaml;
    "unpoller.env".sopsFile = ../secrets.yaml;
  };
}

