{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (cfgNet) address;
in {
  imports = [
    ./adguard.nix
    ./containers.nix
    ./home-assistant
    ./homepage.nix
    ./plex.nix
    ./pocket-id.nix
    ./traefik.nix
  ];

  # TODO: group by type & use consistent values
  nas.ports = {
    actual = 5006;
    adguard = 9900;
    adguarddns = 1053;
    adguard-exporter = 3202;
    apprise = 9005;
    bazarr = 6767;
    beszel = 8090;
    booklore = 6060;
    calibre = 8805;
    calibre-ssl = 8804;
    calibre-server = 8806;
    calibre-web = 8083;
    calibre-device = 8808;
    cockpit = 9090;
    deluge = 8112;
    espresense-companion = 8267;
    flaresolverr = 8191;
    flood = 8113;
    homeassistant = 8123;
    homepage = 8082;
    jackett = 9117;
    jdownloader = 5800;
    jellyfin = 8096;
    jellyfin-alt = 8098;
    jellyfin-vue = 8099;
    jellyseerr = 5055;
    kiwix = 9060;
    koinsights = 8820;
    ladder = 1313;
    lidarr = 8686;
    music-assistant = 8095;
    n8n = 5678;
    navidrome = 4533;
    paperless = 9200;
    pdf = 9208;
    plex = 32400;
    pocket-id = 1411;
    portainer = 9000;
    portainer-agent = 9001;
    prowlarr = 9696;
    qbit = 8811;
    qbit-torrent = 46881;
    qbit-alt = 8810;
    qbit-alt-torrent = 6882;
    qdirstat = 9030;
    radarr = 7878;
    scrutiny = 6080;
    sonarr = 8989;
    startpage = 9009;
    stirling-pdf = 8844;
    syncthing = 8384;
    tautulli = 8181;
    terraria = 7777;
    tubearchivist = 8898;
    unpoller = 9130;
    uptime = 3301;
    watchtower = 3400;
  };

  network.services = {
    music = cfg.ports.navidrome;
    stirling = cfg.ports.stirling-pdf;
  };

  services.flood = {
    enable = true;
    openFirewall = true;

    port = cfg.ports.flood;
    extraArgs = [ "" ];
  };

  services.github-runners = {
    system-builder = {
      enable = true;
      name = "system-builder";
      url = "https://github.com/redxtech/nixfiles";
      tokenFile = config.sops.secrets.ghrunner-system-builder.path;
    };
  };

  services.hercules-ci-agent = {
    enable = true;
    settings = let
      secretPath = name: config.sops.secrets."hercules-ci-agent-${name}".path;
    in {
      binaryCachesPath = secretPath "binary-caches";
      clusterJoinTokenPath = secretPath "join-token";
      secretsJsonPath = secretPath "secrets";
    };
  };

  services.navidrome = {
    enable = true;

    openFirewall = true;
    settings = {
      Address = "0.0.0.0";
      BaseURL = "https://music.${address}";
      DataFolder = "${cfg.paths.config}/navidrome";
      MusicFolder = "${cfg.paths.media}/music";

      # advanced settings
      EnableGravatar = true;
      EnableSharing = true;
      Jukebox.Enabled = true;
      LastFM2.Enabled = true;
      Prometheus.Enabled = true;
    };
  };

  services.stirling-pdf = {
    enable = true;

    environment = {
      SERVER_PORT = cfg.ports.stirling-pdf;
      DISABLE_ADDITIONAL_FEATURES = "false";
    };
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      UPTIME_KUMA_HOST = "0.0.0.0";
      UPTIME_KUMA_PORT = toString cfg.ports.uptime;
    };
  };

  systemd.services.navidrome.serviceConfig.EnvironmentFile =
    config.sops.secrets.navidrome_env.path;

  environment.systemPackages = with pkgs; [ cockpit-zfs-manager ];

  sops.secrets = {
    ghrunner-system-builder.sopsFile = ../secrets.yaml;
    hercules-ci-agent-binary-caches.sopsFile = ../secrets.yaml;
    hercules-ci-agent-binary-caches.owner = "hercules-ci-agent";
    hercules-ci-agent-join-token.sopsFile = ../secrets.yaml;
    hercules-ci-agent-join-token.owner = "hercules-ci-agent";
    hercules-ci-agent-secrets.sopsFile = ../secrets.yaml;
    hercules-ci-agent-secrets.owner = "hercules-ci-agent";
    navidrome_env.sopsFile = ../secrets.yaml;
  };
}
