{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nas;
  defaultEnv = {
    PUID = "config.users.users.${cfg.user}.uid";
    PGID = "config.users.groups.${cfg.group}.gid";
    TZ = cfg.timezone;
  };

  mkCtr = conf: mkIf cfg.useNative conf;
  mkConf = name: cfg.paths.config + "/" + name + ":/config";
  mkData = name: cfg.paths.data + "/" + name + ":/data";
  mkDl = name: cfg.paths.downloads + "/" + name + ":/downloads";
  downloads = cfg.paths.downloads + ":/downloads";
  media = cfg.paths.media + ":/media";
  mkPort = host: guest: "${toString host}:${toString guest}";
in {
  virtualisation.oci-containers = {
    containers = {
      startpage = {
        image = "ghcr.io/redxtech/startpage";
        ports = [ (mkPort cfg.ports.startpage 3000) ];
      };

      portainer = {
        image = "portainer/portainer-ee";
        ports = [ "8000:8000" (mkPort cfg.ports.portainer 9000) ];
        volumes =
          [ "/var/run/docker.sock:/var/run/docker.sock" (mkData "portainer") ];
      };

      portainer-agent = {
        image = "portainer/agent:2.19.4";
        ports = [ (mkPort cfg.ports.portainer-agent 9001) ];
        volumes = [
          "/var/lib/docker/volumes:/var/lib/docker/volumes"
          "/var/run/docker.sock:/var/run/docker.sock"
          "/:/host"
        ];
      };

      adguardhome = mkCtr {
        image = "adguard/adguardhome";
        ports = [
          (mkPort cfg.ports.adguard 3000) # frontend
          "53:53/tcp" # DNS
          "53:53/udp" # DNS
          "67:67/udp" # DHCP
          "68:68/tcp" # DHCP
          "68:68/udp" # DHCP
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
        image = "lscr.io/linuxserver/bazarr";
        environment = defaultEnv;
        ports = [ "${cfg.ports.bazarr}:6767" ];
        volumes = [ (mkConf "bazarr") media ];
      };

      calibre = mkCtr {
        image = "lscr.io/linuxserver/calibre";
        environment = defaultEnv // { PASSWORD = ""; };
        ports = [ "8805:8080" "8806:8081" (mkPort cfg.ports.calibre 8081) ];
        volumes = [
          (mkConf "calibre")
          (cfg.paths.media + "/books:/config/Calibre Library")
        ];
      };

      calibre-web = {
        image = "lscr.io/linuxserver/calibre-web";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.calibre-web 8083) ];
        volumes = [
          (mkConf "calibre-web")
          (cfg.paths.media + "/books:/books")
          # media
        ];
      };

      jackett = mkCtr {
        image = "lscr.io/linuxserver/jackett";
        environment = defaultEnv // { AUTO_UPDATE = "true"; };
        ports = [ (mkPort cfg.ports.jackett 9117) ];
        volumes = [ (mkConf "jackett") downloads ];
      };

      nginx-proxy-manager = {
        image = "jc21/nginx-proxy-manager";
        environment = { TZ = defaultEnv.TZ; };
        ports = [ "80:80" "81:81" "443:443" ];
        volumes = [
          (mkData "nginx-proxy-manager")
          (cfg.paths.config + "/letsencrypt:/etc/letsencrypt")
        ];
      };

      radarr = mkCtr {
        image = "lscr.io/linuxserver/radarr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.radarr 7878) ];
        volumes = [ (mkConf "radarr") downloads media ];
      };

      sonarr = mkCtr {
        image = "lscr.io/linuxserver/sonarr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.sonarr 8989) ];
        volumes = [ (mkConf "sonarr") downloads media ];
      };

      jellyseerr = mkCtr {
        image = "lscr.io/fallenbagel/jellyseerr";
        environment = defaultEnv;
        ports = [ (mkPort cfg.ports.jellyseerr 5055) ];
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
      };

      qbit = {
        image = "lscr.io/linuxserver/qbittorrent";
        environment = defaultEnv // {
          WEBUI_PORT = "${toString cfg.ports.qbit}";
        };
        ports = [
          (mkPort cfg.ports.qbit cfg.ports.qbit)
          "6882:6882"
          "6882:6882/udp"
        ];
        volumes = [ (mkConf "qbit") (mkData "qbit") ];
      };

      qdirstat = {
        image = "lscr.io/linuxserver/qdirstat";
        environment = defaultEnv // {
          CUSTOM_PORT = "${toString cfg.ports.qdirstat}";
        };
        ports = [ (mkPort cfg.ports.qdirstat cfg.ports.qdirstat) ];
        volumes = [ (mkConf "qdirstat") "/:/data:ro" ];
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
      # stash
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
      # traefik
    };
  };
}

