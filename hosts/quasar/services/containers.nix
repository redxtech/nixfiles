{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;

  cfg = config.nas;
  defaultEnv = {
    PUID = toString config.users.users.${cfg.user}.uid;
    PGID = toString config.users.groups.${cfg.group}.gid;
    TZ = cfg.timezone;
  };

  mkConf = name: cfg.paths.config + "/" + name + ":/config";
  mkData = name: cfg.paths.data + "/" + name + ":/data";
  mkDl = name: cfg.paths.downloads + "/" + name + ":/downloads";
  downloads = cfg.paths.downloads + ":/downloads";
  media = cfg.paths.media + ":/media";

  mkPort = host: guest: "${toString host}:${toString guest}";
  mkPorts = port: "${toString port}:${toString port}";
  mkTLstr = name: type: "traefik.http.${type}.${name}"; # make traefik label
  mkTLRstr = name: "${mkTLstr name "routers"}"; # make traefik router label
  mkTLSstr = name: "${mkTLstr name "services"}"; # make traefik router label
  mkLabels = name: {
    "traefik.enable" = "true";
    "${mkTLRstr name}.rule" = "Host(`${name}.${cfg.domain}`)";
    "${mkTLRstr name}.entrypoints" = "websecure";
    "${mkTLRstr name}.tls" = "true";
    "${mkTLRstr name}.tls.certresolver" = "cloudflare";
  };
  mkLabelsPort = name: port:
    {
      "${mkTLSstr name}.loadbalancer.server.port" = "${toString port}";
    } // (mkLabels name);

  someContainersEnabled = false; # dw about it
in {
  virtualisation.oci-containers = {
    containers = {
      # TODO: add to dash, figure out what to do with it
      apprise = mkIf someContainersEnabled {
        image = "lscr.io/linuxserver/apprise-api:latest";
        ports = [ (mkPort cfg.ports.apprise 8000) ];
        labels = mkLabels "apprise";
        environment = defaultEnv;
        volumes = [ (mkConf "apprise") ];
      };

      # TODO: setup
      bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        labels = mkLabels "bazarr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.bazarr 6767) ];
        volumes = [ (mkConf "bazarr") media ];
      };

      calibre = let
        mkHStr = header:
          "${
            mkTLstr "calibre" "middlewares"
          }.headers.customrequestheaders.${header}";
      in {
        image = "lscr.io/linuxserver/calibre:latest";
        labels = (mkLabelsPort "calibre" cfg.ports.calibre-ssl) // {
          "${mkTLSstr "calibre"}.loadbalancer.serverstransport" =
            "ignorecert@file";
          "${mkTLSstr "calibre"}.loadbalancer.server.scheme" = "https";
          "${mkTLRstr "calibre"}.middlewares" = "calibre@docker";
          "${mkHStr "Cross-Origin-Embedder-Policy"}" = "require-corp";
          "${mkHStr "Cross-Origin-Opener-Policy"}" = "same-origin";
          "${mkHStr "Cross-Origin-Resource-Policy"}" = "same-site";
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
        labels = mkLabels "calibre-web";
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

      grocy = mkIf someContainersEnabled {
        image = "lscr.io/linuxserver/grocy:latest";
        labels = mkLabels "grocy";
        ports = [ (mkPorts cfg.ports.grocy) ];
        environment = defaultEnv;
        volumes = [ (mkConf "grocy") ];
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
          JELLYFIN_PublishedServerUrl = "10.0.0.191";
          NVIDIA_VISIBLE_DEVICES = "all";
        };
        ports = [
          (mkPorts cfg.ports.jellyfin)
          (mkPorts 8920)
          "${mkPorts 7359}/udp"
          "${mkPorts 1900}/udp"
        ];
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
          DEFAULT_SERVERS =
            "http://quasar:8096,https://jellyfin.${cfg.domain},192.168.50.208:8096,demo.jellyfin.org";
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
        # labels = mkLabelsPort "kiwix" cfg.ports.kiwix;
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
          "wikipedia_en_all_maxi_2022-05.zim"
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

      ladder-alt = {
        image = "wasimaster/13ft:latest";
        labels = (mkLabels "13ft") // {
          "${mkTLRstr "13ft"}.rule" = "Host(`13ft.short.af`)";
        };
        ports = [ (mkPort 1111 5000) ];
      };

      nest-rtsp = {
        image = "jakguru/nest-rtsp:master";
        environment = defaultEnv // {
          HTTP_PORT = "${toString cfg.ports.nest-rtsp}";
        };
        environmentFiles = [ config.sops.secrets.nest-rtsp.path ];
        extraOptions = [ "--network" "host" "--privileged" ];
      };

      paperless = {
        image = "lscr.io/linuxserver/paperless-ngx:latest";
        labels = mkLabels "paperless";
        environment = defaultEnv // { };
        ports = [ (mkPort cfg.ports.paperless 8000) ];
        volumes = [ (mkConf "paperless") (mkData "paperless") ];
      };

      portainer = {
        image = "portainer/portainer-ee:latest";
        ports = [ "8000:8000" (mkPort cfg.ports.portainer 9000) ];
        volumes =
          [ "/var/run/docker.sock:/var/run/docker.sock" (mkData "portainer") ];
        extraOptions = [ "--network" "host" ];
      };

      portainer-agent = {
        image = "portainer/agent:latest";
        ports = [ (mkPort cfg.ports.portainer-agent 9001) ];
        volumes = [
          "/var/lib/docker/volumes:/var/lib/docker/volumes"
          "/var/run/docker.sock:/var/run/docker.sock"
          "/:/host"
        ];
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
          CUSTOM_PORT = "${toString cfg.ports.qdirstat}";
        };
        ports = [ (mkPorts cfg.ports.qdirstat) ];
        volumes = [ (mkConf "qdirstat") "/:/data:ro" ];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.radarr 7878) ];
        volumes = [ (mkConf "radarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.sonarr 8989) ];
        volumes = [ (mkConf "sonarr") downloads media ];
        extraOptions = [ "--network" "host" ];
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

      tandoor = {
        image = "vabene1111/recipes";
        labels = mkLabels "tandoor";
        environment = defaultEnv // {
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "tandoor-postgres";
          POSTGRES_PORT = "5432";
          POSTGRES_DB = "tandoor";
        };
        environmentFiles = [ config.sops.secrets.tandoor_env.path ];
        ports = [ (mkPort cfg.ports.tandoor 8080) ];
        volumes = [
          "${cfg.paths.config}/tandoor/static:/opt/recipes/staticfiles"
          "${cfg.paths.config}/tandoor/media:/opt/recipes/mediafiles"
        ];
        extraOptions = [ "--network" "tandoor" ];
      };

      tandoor-postgres = {
        image = "postgres:latest";
        environment = defaultEnv // {
          POSTGRES_DB = "tandoor";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        environmentFiles = [ config.sops.secrets.tandoor_env.path ];
        ports = [ (mkPorts 5432) ];
        volumes =
          [ "${cfg.paths.config}/tandoor-postgres:/var/lib/postgresql/data" ];
        extraOptions = [ "--network" "tandoor" ];
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

      watchtower = {
        image = "containrrr/watchtower:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.watchtower 8080) ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };

      # pairdrop
      # lidarr
      # airsonic (advanced?)
      # modded-mc
      # organizr
      # invoice ninja
      # lychee/immich/photoprism
      # emulatorjs
      # nextcloud
      # wireguard
      # tubearchivist
      # home-assistant
      # readarr
      # duplicati/duplicacy

      # fireshare
      # tmod
      # pingbot
    };
  };

  system.activationScripts.mkDockerNetworks =
    let networks = [ "paperless" "tandoor" ];
    in ''
      for network in ${toString networks}; do
        ${pkgs.docker}/bin/docker network inspect $network >/dev/null 2>&1 ||
          ${pkgs.docker}/bin/docker network create --driver bridge $network
      done
    '';

  sops.secrets."ddclient.conf".sopsFile = ../secrets.yaml;
  sops.secrets.calibre_user.sopsFile = ../secrets.yaml;
  sops.secrets.calibre_pw.sopsFile = ../secrets.yaml;
  sops.secrets.nest-rtsp.sopsFile = ../secrets.yaml;
  sops.secrets.tandoor_env.sopsFile = ../secrets.yaml;
}

