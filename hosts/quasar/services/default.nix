{ pkgs, lib, config, ... }:

with lib;
let cfg = config.nas;
in {
  imports =
    [ ./adguard.nix ./containers.nix ./dashboard.nix ./plex.nix ./traefik.nix ];

  # TODO: group by type & use consistent values
  nas.ports = {
    adguard = 9900;
    apprise = 9005;
    attic = 3090;
    bazarr = 6767;
    calibre = 8805;
    calibre-ssl = 8804;
    calibre-server = 8806;
    calibre-web = 8807;
    cockpit = 9090;
    dashy = 4000;
    deluge = 8112;
    flaresolverr = 8191;
    grocy = 9283;
    jackett = 9117;
    jellyfin = 8096;
    jellyfin-vue = 8099;
    jellyseerr = 5055;
    kiwix = 9060;
    ladder = 1313;
    lidarr = 8686;
    monica = 6901;
    mysql = 3306;
    nest-rtsp = 7001;
    netdata = 19999;
    paperless = 9200;
    plex = 32400;
    portainer = 9000;
    portainer-agent = 9001;
    psend = 9010;
    psend-mysql = 9910;
    prowlarr = 9696;
    qbit = 8810;
    qdirstat = 9030;
    radarr = 7878;
    startpage = 9009;
    syncthing = 8384;
    sonarr = 8989;
    tandoor = 9700;
    tautulli = 8181;
    uptime-kuma = 3001;
  };

  services = let
    mkConf = name: cfg.paths.config + "/" + name + ":/config";
    mkData = name: cfg.paths.data + "/" + name + ":/data";
    downloads = cfg.paths.downloads + ":/downloads";
    media = cfg.paths.media + ":/media";
  in {
    # override the default configuration to enable ssl
    cockpit.settings.WebService = let port = toString cfg.ports.cockpit;
    in {
      Origins = lib.concatStringsSep " " [
        "https://${cfg.domain}"
        "wss://${cfg.domain}"
        "http://localhost:${port}"
        "ws://localhost:${port}"
        "http://quasar:${port}"
        "ws://quasar:${port}"
      ];
      ProtocolHeader = "X-Forwarded-Proto";
    };

    traefik.dynamicConfigOptions.http =
      lib.mkIf config.services.traefik.enable {
        routers.cockpit = {
          rule = "Host(`${config.nas.domain}`)";
          service = "cockpit";
          entrypoints = [ "websecure" ];
        };
        services.cockpit.loadBalancer.servers =
          [{ url = "http://localhost:${toString config.nas.ports.cockpit}"; }];
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

    github-runners = {
      system-builder = {
        enable = true;
        name = "system-builder";
        url = "https://github.com/redxtech/nixfiles";
        tokenFile = config.sops.secrets.ghrunner-system-builder.path;
      };
    };

    hercules-ci-agent = {
      enable = true;
      settings = let
        secretPath = name: config.sops.secrets."hercules-ci-agent-${name}".path;
      in {
        binaryCachesPath = secretPath "binary-caches";
        clusterJoinTokenPath = secretPath "join-token";
        secretsJsonPath = secretPath "secrets";
      };
    };

    atticd = {
      enable = true;
      credentialsFile = config.sops.secrets.attic.path;

      settings = {
        listen = "[::]:${toString cfg.ports.attic}";
        chunking = {
          # if 0, chunking is disabled entirely for newly-uploaded NARs.
          # if 1, all NARs are chunked.
          nar-size-threshold = 64 * 1024; # 64 KiB
          min-size = 16 * 1024; # 16 KiB
          avg-size = 64 * 1024; # 64 KiB
          max-size = 256 * 1024; # 256 KiB
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ cockpit-zfs-manager ];

  sops.secrets.attic.sopsFile = ../secrets.yaml;

  sops.secrets.ghrunner-system-builder.sopsFile = ../secrets.yaml;

  sops.secrets.hercules-ci-agent-binary-caches.sopsFile = ../secrets.yaml;
  sops.secrets.hercules-ci-agent-binary-caches.owner = "hercules-ci-agent";
  sops.secrets.hercules-ci-agent-join-token.sopsFile = ../secrets.yaml;
  sops.secrets.hercules-ci-agent-join-token.owner = "hercules-ci-agent";
  sops.secrets.hercules-ci-agent-secrets.sopsFile = ../secrets.yaml;
  sops.secrets.hercules-ci-agent-secrets.owner = "hercules-ci-agent";
}
