{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.nas;
  cfgNet = config.network;
in {
  imports =
    [ ./adguard.nix ./containers.nix ./dashboard.nix ./plex.nix ./traefik.nix ];

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
    flaresolverr = 8191;
    jackett = 9117;
    jellyfin = 8096;
    jellyfin-vue = 8099;
    jellyseerr = 5055;
    kiwix = 9060;
    ladder = 1313;
    lidarr = 8686;
    paperless = 9200;
    pdf = 9208;
    plex = 32400;
    portainer = 9000;
    portainer-agent = 9001;
    prowlarr = 9696;
    qbit = 8810;
    qdirstat = 9030;
    radarr = 7878;
    startpage = 9009;
    syncthing = 8384;
    sonarr = 8989;
    tandoor = 9700;
    tautulli = 8181;
    uptime = 3301;
  };

  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "0.0.0.0";
        UPTIME_KUMA_PORT = toString cfg.ports.uptime;
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
  };

  environment.systemPackages = with pkgs; [ cockpit-zfs-manager ];

  sops.secrets = {
    ghrunner-system-builder.sopsFile = ../secrets.yaml;
    hercules-ci-agent-binary-caches.sopsFile = ../secrets.yaml;
    hercules-ci-agent-binary-caches.owner = "hercules-ci-agent";
    hercules-ci-agent-join-token.sopsFile = ../secrets.yaml;
    hercules-ci-agent-join-token.owner = "hercules-ci-agent";
    hercules-ci-agent-secrets.sopsFile = ../secrets.yaml;
    hercules-ci-agent-secrets.owner = "hercules-ci-agent";
  };
}
