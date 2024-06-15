{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "bastion";
    fs.btrfs = true;
    dockerDNS = [ "192.168.50.1" ];
    yubiauth.lockOnRemove.enable = true;

    gpu = {
      enable = true;
      amd = true;
    };
  };

  desktop = {
    enable = true;
    useZen = true;
    wm = "bspwm";

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

  backup = {
    btrfs = {
      enable = true;
      subvolumes = { gabe-home = "/home/gabe"; };
    };
  };

  nixpkgs.config.rocmSupport = true;

  virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent-bastion.path = "/etc/cachix-agent.token";

  system.stateVersion = "23.11";
}
