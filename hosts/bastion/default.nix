{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "bastion";
    fs.btrfs = true;
    dockerDNS = [ "192.168.50.1" ];
  };

  desktop = {
    enable = true;
    useZen = true;
    wm = "bspwm";

    ai.enable = true;

    gaming = {
      enable = true;
      amd = true;
      sunshine = {
        enable = true;
        monitor = "DisplayPort-0";
        monitorIndex = 1;
      };
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
