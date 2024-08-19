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
    dockerDNS = [ "192.168.50.1" ];

    fs = {
      btrfs = true;
      zfs = true;
    };

    gpu = {
      enable = true;
      # nvidia.enable = true;
    };

    services = {
      portainer.enable = false; # handled by ./services/containers.nix
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

  monitoring.enable = true;
  monitoring.isHost = true;

  backup = {
    rsync = {
      enable = true;
      paths = [ "/config" ];
      destination = "rsync:/backups/${config.networking.hostName}";
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  sops.secrets.cachix-agent = {
    path = "/etc/cachix-agent.token";
    sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "23.11";
}
