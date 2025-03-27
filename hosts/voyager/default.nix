{ config, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "voyager";
    fs.btrfs = true;

    gpu = {
      enable = true;
      amd = true;
    };

    clamav.daily = false;
  };

  desktop = {
    enable = true;
    isLaptop = true;
    useZen = true;
    remap = true;
    wm = "hyprland";

    gaming = {
      enable = true;
      amd = true;

      prime = {
        enable = true;
        internal = "pci-0000_c4_00_0";
        dedicated = "pci-0000_03_00_0";
      };
    };
  };

  monitoring.enable = true;

  backup = {
    btrfs = {
      enable = false; # TODO: enable
      subvolumes.gabe-home = "/home/gabe";
    };
    restic = {
      enable = true;
      backups = {
        home = {
          enable = true;
          repoFile = config.sops.secrets.restic_repository_home.path;
          passFile = config.sops.secrets.restic_password.path;
        };
      };
    };
  };

  # nixpkgs.config.rocmSupport = true;

  virtualisation.docker.storageDriver = "btrfs";

  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 2;

  sops.secrets = {
    cachix-agent = {
      path = "/etc/cachix-agent.token";
      sopsFile = ./secrets.yaml;
    };
    restic_password.sopsFile = ./secrets.yaml;
    restic_repository_config.sopsFile = ./secrets.yaml;
    restic_repository_home.sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "24.05";
}
