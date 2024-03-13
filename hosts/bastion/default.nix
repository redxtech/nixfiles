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

    ../common/optional/bspwm.nix
    ../common/optional/hyprland.nix
    ../common/optional/btrfs.nix
    ../common/optional/fonts.nix
    ../common/optional/gaming.nix
    ../common/optional/logitech.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    # ../common/optional/rdp.nix
    ../common/optional/security.nix
    ../common/optional/steam-hardware.nix
    ../common/optional/systemd-boot.nix
  ];

  base = {
    enable = true;
    hostname = "bastion";
    tz = "America/Vancouver";
  };

  desktop = {
    enable = true;
    useZen = true;
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
