{ pkgs, lib, config, ... }:

with lib;
let cfg = config.nas;
in {
  imports = [ ./containers.nix ./plex.nix ];

  nas.ports = {
    bazarr = 6767;
    calibre = 9001;
    calibre-web = 9002;
    deluge = 8112;
    jackett = 9117;
    jellyfin = 8096;
    jellyseerr = 5055;
    lidarr = 8686;
    plex = 32400;
    portainer = 9000;
    radarr = 7878;
    startpage = 9009;
    sonarr = 8989;
    tautulli = 8181;
  };

  services = let
    mkNtv = conf: mkIf (!cfg.useNative) conf;
    mkConf = name: cfg.paths.config + "/" + name + ":/config";
    mkData = name: cfg.paths.data + "/" + name + ":/data";
    downloads = cfg.paths.downloads + ":/downloads";
    media = cfg.paths.media + ":/media";
  in {
    bazarr = mkNtv {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      listenPort = cfg.ports.bazarr;
    };

    calibre-server = mkNtv {
      enable = true;

      user = cfg.user;
      group = cfg.group;
      port = cfg.ports.calibre;

      libraries = [ "${cfg.paths.media}/books" ];
      # auth.enable = true;
    };

    calibre-web = mkNtv {
      enable = false;

      user = cfg.user;
      group = cfg.group;

      dataDir = "${cfg.paths.data}/calibre-web";
      listen.port = cfg.ports.calibre-web;
      openFirewall = true;

      options = {
        enableBookConversion = true;
        enableBookUploading = true;
        calibreLibrary = "${cfg.paths.media}/books";
      };
    };

    deluge = mkNtv {
      enable = true;

      user = cfg.user;
      group = cfg.group;
      web.port = cfg.ports.deluge;
      web.openFirewall = true;

      dataDir = cfg.paths.data + "/deluge";
      extraPackages = with pkgs; [ ];

      declarative = true;
      authFile = config.sops.secrets.deluge-auth.path;
      openFirewall = true;
      config = { };
    };

    jackett = mkNtv {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = true;
      dataDir = "${cfg.paths.data}/jackett";
    };

    radarr = mkNtv {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = true;
      dataDir = "${cfg.paths.data}/radarr";
    };

    sonarr = mkNtv {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = true;
      dataDir = "${cfg.paths.data}/sonarr";
    };

    jellyseerr = mkNtv {
      enable = true;
      port = cfg.ports.jellyseerr;
      openFirewall = true;
    };
  };

  sops.secrets.deluge-auth = {
    sopsFile = ../secrets.yaml;
    owner = cfg.user;
    mode = "0644";
  };
}
