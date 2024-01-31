{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nas;
  defaultEnv = {
    PUID = "config.users.users.${cfg.user}.uid";
    PGID = "config.users.groups.${cfg.group}.gid";
    TZ = cfg.timezone;
  };

  mkCtr = conf: mkIf (!cfg.useNative) conf;
  mkConf = name: cfg.paths.config + "/" + name + ":/config";
  mkData = name: cfg.paths.data + "/" + name + ":/data";
  mkDl = name: cfg.paths.downloads + "/" + name + ":/downloads";
  downloads = cfg.paths.downloads + ":/downloads";
  media = cfg.paths.media + ":/media";
  mkPort = host: guest: "${toString host}:${toString guest}";
  mkPorts = port: "${toString port}:${toString port}";
  mkLabels = name: {
    "traefik.enable" = "true";
    "traefik.http.routers.${name}.rule" = "Host(`${name}.${cfg.domain}`)";
    "traefik.http.routers.${name}.entrypoints" = "websecure";
    "traefik.http.routers.${name}.tls" = "true";
    "traefik.http.routers.${name}.tls.certresolver" = "cloudflare";
  };
  mkLabelsPort = name: port:
    {
      "traefik.http.services.${name}.loadbalancer.server.port" =
        "${toString port}";
    } // (mkLabels name);
in {
  virtualisation.oci-containers = {
    containers = {
      startpage = {
        image = "ghcr.io/redxtech/startpage:latest";
        labels = mkLabels "startpage";
        ports = [ (mkPort cfg.ports.startpage 3000) ];
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

      adguardhome = mkCtr {
        image = "adguard/adguardhome:latest";
        labels = mkLabelsPort "adguard" cfg.ports.adguard;
        ports = [
          (mkPort cfg.ports.adguard 3000) # frontend
          "53:53/tcp" # DNS
          "53:53/udp" # DNS
          # "67:67/udp" # DHCP
          # "68:68/tcp" # DHCP
          # "68:68/udp" # DHCP
          #     "80:80/tcp" # DNS over HTTPS
          #     "443:443/tcp" # DNS over HTTPS
          #     "443:443/udp" # DNS over HTTPS
          "853:853/tcp" # DNS over TLS
          # "784:784/udp" # DNS over QUIC
          # "853:853/udp" # DNS over QUIC
          # "8853:8853/udp" # DNS over QUIC
          # "5443:5443/tcp" # DNScrypt
          # "5443:5443/udp" # DNScrypt
        ];
        volumes = [
          "${toString cfg.paths.config}/adguard:/opt/adguardhome/conf"
          "${toString cfg.paths.data}/adguard:/opt/adguardhome/work"
        ];
      };

      bazarr = mkCtr {
        image = "lscr.io/linuxserver/bazarr:latest";
        labels = mkLabels "bazarr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.bazarr 6767) ];
        volumes = [ (mkConf "bazarr") media ];
      };

      calibre = mkCtr {
        image = "lscr.io/linuxserver/calibre:latest";
        labels = mkLabels "calibre";
        environment = defaultEnv // { PASSWORD = ""; };
        ports = [ "8805:8080" "8806:8081" (mkPort cfg.ports.calibre 8081) ];
        volumes = [
          (mkConf "calibre")
          (cfg.paths.media + "/books:/config/Calibre Library")
        ];
      };

      calibre-web = {
        image = "lscr.io/linuxserver/calibre-web:latest";
        labels = mkLabels "calibre-web";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.calibre-web 8083) ];
        volumes = [
          (mkConf "calibre-web")
          (cfg.paths.media + "/books:/books")
          # media
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

      jackett = mkCtr {
        image = "lscr.io/linuxserver/jackett:latest";
        labels = mkLabels "jackett";
        environment = defaultEnv // { AUTO_UPDATE = "true"; };
        ports = [ (mkPort cfg.ports.jackett 9117) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      radarr = mkCtr {
        image = "lscr.io/linuxserver/radarr:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.radarr 7878) ];
        volumes = [ (mkConf "radarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      sonarr = mkCtr {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.sonarr 8989) ];
        volumes = [ (mkConf "sonarr") downloads media ];
        extraOptions = [ "--network" "host" ];
      };

      jellyseerr = mkCtr {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkLabels "jellyseerr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.jellyseerr 5055) ];
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
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

      qdirstat = {
        image = "lscr.io/linuxserver/qdirstat:latest";
        labels = mkLabels "qdirstat";
        environment = defaultEnv // {
          CUSTOM_PORT = "${toString cfg.ports.qdirstat}";
        };
        ports = [ (mkPorts cfg.ports.qdirstat) ];
        volumes = [ (mkConf "qdirstat") "/:/data:ro" ];
      };

      tautulli = mkCtr {
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
      # dashy
      # flaresolverr
      # jellyfin
      # kiwix
      # lidarr
      # mc
      # modded-mc
      # pingbot
      # tubearchivist

      # ddclient
      # duplicati
      # gitea
      # grocy
      # home-assistant
      # monica
      # nextcloud
      # readarr
      # tmod
    };
  };

  sops.secrets."ddclient.conf".sopsFile = ../secrets.yaml;
}

