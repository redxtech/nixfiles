{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "bastion";
    tz = "America/Vancouver";
    fs.btrfs = true;
  };

  desktop = {
    enable = true;
    useZen = true;
    wm = "bspwm";

    gaming = {
      enable = true;
      amd = true;
      sunlight = true;
    };
  };

  backup = {
    btrfs = {
      enable = true;
      subvolumes = { gabe-home = "/home/gabe"; };
    };
  };

  virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent-bastion.path = "/etc/cachix-agent.token";

  system.stateVersion = "23.11";
}
