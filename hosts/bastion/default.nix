{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    ./filesystem.nix
    ./services.nix
    ./cachix.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    # ../common/optional/rdp.nix
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

  system.stateVersion = "23.11";
}
