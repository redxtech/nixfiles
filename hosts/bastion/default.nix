{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "bastion";
    fs.btrfs = true;
    dockerDNS = [ "192.168.1.1" ];
    yubiauth.lockOnRemove.enable = true;

    gpu = {
      enable = true;
      amd = true;
    };
  };

  desktop = {
    enable = true;
    useZen = true;
    wm = "hyprland";

    gaming = {
      enable = true;
      amd = true;
      sunshine = {
        enable = true;
        monitor = "DisplayPort-0";
        monitorIndex = 1;
      };
    };

    ai = {
      enable = true;
      web-ui = true;
    };
  };

  network = {
    enable = true;
    ip = "192.168.1.55";
    tunnelID = "10f40833-b341-4f16-9920-2b5796744e15";
  };

  networking.firewall.allowedTCPPorts = [ 25565 24454 ];

  monitoring.enable = true;

  backup = {
    btrfs = {
      enable = true;
      subvolumes = { gabe-home = "/home/gabe"; };
    };

    restic = {
      enable = true;
      backups = {
        config = {
          enable = true;
          repoFile = config.sops.secrets.restic_repository_config.path;
          passFile = config.sops.secrets.restic_password.path;
        };
        home = {
          enable = true;
          repoFile = config.sops.secrets.restic_repository_home.path;
          passFile = config.sops.secrets.restic_password.path;
        };
      };
    };
  };

  nixpkgs.config.rocmSupport = true;

  virtualisation.docker.storageDriver = "btrfs";

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
