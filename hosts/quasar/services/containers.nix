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
        image = "portainer/portainer-ce";
        ports = [ "8000:8000" (mkPort cfg.ports.portainer 9000) ];
        volumes =
          [ "/var/run/docker.sock:/var/run/docker.sock" (mkConf "portainer") ];
      };

      bazarr = mkCtr {
        image = "lscr.io/linuxserver/bazarr";
        ports = [ "${cfg.ports.bazarr}:6767" ];
        environment = defaultEnv;
        volumes = [ (mkConf "bazarr") media ];
      };

      calibre = mkCtr {
        image = "lscr.io/linuxserver/calibre";
        ports = [
          "8805:8080"
          "8806:8081"
          # "${cfg.ports.calibre}:8081"
        ];
        environment = defaultEnv // { PASSWORD = ""; };
        volumes = [
          (mkConf "calibre")
          (cfg.paths.media + "/books:/config/Calibre Library")
        ];
      };

      calibre-web = mkCtr {
        image = "lscr.io/linuxserver/calibre-web";
        ports = [ "${cfg.ports.calibre-web}:8083" ];
        environment = defaultEnv;
        volumes = [
          (mkConf "calibre-web")
          (cfg.paths.media + "/books:/books")
          # media
        ];
      };

      jackett = mkCtr {
        image = "lscr.io/linuxserver/jackett";
        ports = [ "${cfg.ports.jackett}:9117" ];
        environment = defaultEnv // { AUTO_UPDATE = "true"; };
        volumes = [ (mkConf "jackett") downloads ];
      };

      nginx-proxy-manager = {
        image = "jc21/nginx-proxy-manager";
        ports = [ "80:80" "81:81" "443:443" ];
        environment = defaultEnv;
        volumes = [
          (mkData "nginx-proxy-manager")
          (cfg.paths.config + "/letsencrypt:/etc/letsencrypt")
        ];
      };

      radarr = mkCtr {
        image = "lscr.io/linuxserver/radarr";
        ports = [ "${cfg.ports.radarr}:7878" ];
        environment = defaultEnv;
        volumes = [ (mkConf "radarr") downloads media ];
      };

      sonarr = mkCtr {
        image = "lscr.io/linuxserver/sonarr";
        ports = [ "${cfg.ports.sonarr}:8989" ];
        environment = defaultEnv;
        volumes = [ (mkConf "sonarr") downloads media ];
      };

      jellyseerr = mkCtr {
        image = "lscr.io/fallenbagel/jellyseerr";
        ports = [ "${cfg.ports.jellyseerr}:5055" ];
        environment = defaultEnv;
        volumes = [ (cfg.paths.config + "/jellyseerr:/app/config") ];
      };

      # certbot
      # cockpit
      # dashy
      # flaresolverr
      # kiwix
      # lidarr
      # mc
      # modded-mc
      # pingbot
      # qdirstat
      # stash
      # tubearchivist

      # adguard
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
}
