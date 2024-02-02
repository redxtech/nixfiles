{ config, pkgs, lib, ... }:

with lib;
let
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
in {
  virtualisation.oci-containers = {
    containers = {
      # TODO: dash, figure out what to do with it
      # apprise = {
      #   image = "lscr.io/linuxserver/apprise-api:latest";
      #   ports = [ (mkPort cfg.ports.apprise 8000) ];
      #   labels = mkLabels "apprise";
      #   environment = defaultEnv;
      #   volumes = [ (mkConf "apprise") ];
      # };

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
        ports = [ (mkPorts cfg.ports.deluge) "6881:6881" "6881:6881/udp" ];
        environment = defaultEnv;
        volumes = [ (mkConf "deluge") (mkDl "deluge") ];
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
        labels = mkLabels "jellyfin";
        environment = defaultEnv // {
          JELLYFIN_PublishedServerUrl = "10.0.0.191";
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
            "quasar:8096,jellyfin.${cfg.domain},10.0.0.191:8096,demo.jellyfin.org";
          HISTORY_ROUTER_MODE = "0";
        };
        ports = [ (mkPort cfg.ports.jellyfin-vue 80) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkLabels "jellyseerr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.jellyseerr 5055) ];
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
      };

      monica = {
        image = "lscr.io/linuxserver/monica:latest";
        hostname = "monica";
        labels = mkLabels "monica";
        environment = defaultEnv // {
          # APP_URL = "https://monica.${cfg.domain}";
          DB_HOST = "mysql";
          DB_USERNAME = "monica";
          DB_DATABASE = "monica";
        };
        environmentFiles = [ config.sops.secrets.monica_env.path ];
        ports = [ (mkPort cfg.ports.monica 80) ];
        volumes = [ (mkConf "monica") ];
        extraOptions = [ "--network" "monica" ];
      };

      mysql = {
        image = "mysql:latest";
        hostname = "mysql";
        environment = defaultEnv // {
          MYSQL_RANDOM_ROOT_PASSWORD = "true";
          MYSQL_DATABASE = "monica";
          MYSQL_USER = "monica";
        };
        environmentFiles = [ config.sops.secrets.monica_env.path ];
        ports = [ (mkPort cfg.ports.mysql 3306) ];
        volumes = [ (mkConf "mysql") ];
        extraOptions = [ "--network" "monica" ];
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
        ];
      };

      # TODO: setup
      qdirstat = {
        image = "lscr.io/linuxserver/qdirstat:latest";
        labels = mkLabels "qdirstat";
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

      startpage = {
        image = "ghcr.io/redxtech/startpage:latest";
        labels = mkLabels "startpage";
        ports = [ (mkPort cfg.ports.startpage 3000) ];
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

      # certbot
      # flaresolverr
      # kiwix
      # lidarr
      # mc
      # modded-mc
      # pingbot
      # tubearchivist

      # duplicati
      # grocy
      # home-assistant
      # nextcloud
      # readarr
      # tmod
    };
  };

  system.activationScripts.mkDockerNetworks = let networks = [ "monica" ];
  in ''
    for network in ${toString networks}; do
      ${pkgs.docker}/bin/docker network inspect $network >/dev/null 2>&1 ||
        ${pkgs.docker}/bin/docker network create --driver bridge $network
    done
  '';

  sops.secrets."ddclient.conf".sopsFile = ../secrets.yaml;
  sops.secrets.calibre_user.sopsFile = ../secrets.yaml;
  sops.secrets.calibre_pw.sopsFile = ../secrets.yaml;
  sops.secrets.monica_env.sopsFile = ../secrets.yaml;
}

