{ pkgs, lib, config, ... }:

with lib;
let cfg = config.nas;
in {
  imports = [
    ./adguard.nix
    ./containers.nix
    ./dashboard.nix
    # ./minecraft.nix
    ./plex.nix
    ./traefik.nix
  ];

  # TODO: group by type & use consistent values
  nas.ports = {
    adguard = 9900;
    apprise = 9005;
    bazarr = 6767;
    calibre = 8805;
    calibre-ssl = 8804;
    calibre-server = 8806;
    calibre-web = 8807;
    cockpit = 9090;
    dashy = 4000;
    deluge = 8112;
    jackett = 9117;
    jellyfin = 8096;
    jellyfin-vue = 8099;
    jellyseerr = 5055;
    lidarr = 8686;
    minecraft = 25565;
    monica = 6901;
    mysql = 3306;
    netdata = 19999;
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
    mkConf = name: cfg.paths.config + "/" + name + ":/config";
    mkData = name: cfg.paths.data + "/" + name + ":/data";
    downloads = cfg.paths.downloads + ":/downloads";
    media = cfg.paths.media + ":/media";
  in {
    cockpit.settings.WebService = {
      Origins = lib.concatStringsSep " " [
        "https://${cfg.domain}"
        "wss://${cfg.domain}"
        "http://quasar:${toString cfg.ports.cockpit}"
        "ws://quasar:${toString cfg.ports.cockpit}"
      ];
      ProtocolHeader = "X-Forwarded-Proto";
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
