{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./filesystem.nix
  ];

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
    };
  };

  backup = {
    btrfs = {
      enable = true;
      subvolumes = { gabe-home = "/home/gabe"; };
    };
  };

  virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent.sopsFile = ./secrets.yaml;
  sops.secrets.cachix-agent.path = "/etc/cachix-agent.token";

  system.stateVersion = "23.11";
}
