{ pkgs, lib, config, ... }:

with lib;
let cfg = config.nas;
in {
  imports = [
    ./containers.nix
    ./dashboard.nix
    # ./minecraft.nix
    ./plex.nix
    ./traefik.nix
  ];

  nas.ports = {
    adguard = 9900;
    bazarr = 6767;
    calibre = 9003;
    calibre-web = 9002;
    cockpit = 9090;
    dashy = 4000;
    deluge = 8112;
    jackett = 9117;
    jellyfin = 8096;
    jellyseerr = 5055;
    lidarr = 8686;
    netdata = 19999;
    minecraft = 25565;
    plex = 32400;
    portainer = 9000;
    portainer-agent = 9001;
    qbit = 8810;
    qdirstat = 9030;
    radarr = 7878;
    startpage = 9009;
    sonarr = 8989;
    tautulli = 8181;
    uptime-kuma = 3001;
  };

  services = let
    mkNtv = conf: mkIf cfg.useNative conf;
    mkConf = name: cfg.paths.config + "/" + name + ":/config";
    mkData = name: cfg.paths.data + "/" + name + ":/data";
    downloads = cfg.paths.downloads + ":/downloads";
    media = cfg.paths.media + ":/media";
  in {
    adguardhome = mkNtv {
      enable = true;
      openFirewall = true;
      settings = { bind_port = cfg.ports.adguard; };
    };

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

    jackett = mkNtv {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = true;
      dataDir = "${cfg.paths.data}/jackett";
    };

    jellyseerr = mkNtv {
      enable = true;
      port = cfg.ports.jellyseerr;
      openFirewall = true;
    };

    netdata = {
      enable = false;

      group = "docker";

      python.extraPackages = ps:
        with ps; [
          psycopg2
          docker
          dnspython
          numpy
          pandas
        ];

      config = { web."default port" = toString cfg.ports.netdata; };
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

    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "0.0.0.0";
        UPTIME_KUMA_PORT = toString cfg.ports.uptime-kuma;
      };
    };
  };

  environment.systemPackages = with pkgs; [ cockpit-zfs-manager ];
}
