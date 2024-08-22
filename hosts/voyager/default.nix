{ lib, ... }:

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
  };

  desktop = {
    enable = true;
    isLaptop = true;
    useZen = true;
    remap = true;
    wm = "hyprland";

    gaming = {
      enable = false; # TODO: enable
      amd = true;
    };
  };

  monitoring.enable = true;

  backup = {
    btrfs = {
      enable = false; # TODO: enable
      subvolumes.gabe-home = "/home/gabe";
    };
  };

  # nixpkgs.config.rocmSupport = true;

  virtualisation.docker.storageDriver = "btrfs";

  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 2;

  sops.secrets.cachix-agent = {
    path = "/etc/cachix-agent.token";
    sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "24.05";
}
