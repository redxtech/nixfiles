{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "bastion";
    fs.btrfs = true;
    dockerDNS = [ config.network.hostIP ];
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
    ip = "10.0.0.55";
    tunnelID = "10f40833-b341-4f16-9920-2b5796744e15";
  };

  monitoring.enable = true;

  backup = {
    btrfs = {
      enable = true;
      subvolumes = { gabe-home = "/home/gabe"; };
    };
  };

  nixpkgs.config.rocmSupport = true;

  virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent = {
    path = "/etc/cachix-agent.token";
    sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "23.11";
}
