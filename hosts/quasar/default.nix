{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./filesystem.nix

    ./services
  ];

  base = {
    enable = true;
    hostname = "quasar";
    dockerDNS = [ "192.168.1.1" ];

    fs = {
      btrfs = true;
      zfs = true;
    };

    gpu = {
      enable = true;
      # nvidia.enable = true;
    };
  };

  desktop = {
    enable = true;
    wm = "gnome";
  };

  nas = {
    enable = true;
    domain = "nas.gabedunn.dev";
    paths.config = "/config/pods";
  };

  network = {
    enable = true;
    isHost = true;
    ip = "192.168.1.191";
    tunnelID = "7f867cbe-8898-4ff6-be4c-8a3ab626b456";

    services = {
      grafana = 3000;
      lidarr = 8686;
      radarr = 7878;
      sonarr = 8989;
      uptime = 3301;
    };
  };

  monitoring.enable = true;
  monitoring.isHost = true;

  backup = {
    restic = {
      enable = true;
      backups = {
        config = {
          enable = true;
          repoFile = config.sops.secrets.restic_repository_config.path;
          passFile = config.sops.secrets.restic_password.path;
          extraPaths = [ "/config" ];
        };
      };
    };

    rsync = {
      enable = true;
      paths = [ "/config" "/var/lib" ];
      destination = "rsync:/backups/${config.networking.hostName}";
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  sops.secrets = {
    cachix-agent = {
      path = "/etc/cachix-agent.token";
      sopsFile = ./secrets.yaml;
    };
    restic_password.sopsFile = ./secrets.yaml;
    restic_repository_config.sopsFile = ./secrets.yaml;
    restic_repository_home.sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "23.11";
}
