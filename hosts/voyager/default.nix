{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-7590-nvidia

    ./hardware-configuration.nix
    ./filesystem.nix
    ./services.nix
    ./cachix.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    ../common/optional/bspwm.nix
  ];

  base = {
    enable = true;
    hostname = "voyager";
    tz = "America/Vancouver";
  };

  desktop = {
    enable = true;
    isLaptop = true;
    useZen = true;

    gaming = {
      enable = true;
      prime = true;
      nvidia = true;
    };
  };

  # virtualisation.docker.storageDriver = "btrfs";

  system.stateVersion = "22.11";
}
