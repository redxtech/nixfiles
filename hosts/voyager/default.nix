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
    ../common/optional/containers.nix
    ../common/optional/desktop-apps.nix
    ../common/optional/extra.nix
    ../common/optional/fail2ban.nix
    ../common/optional/flatpak.nix
    ../common/optional/fonts.nix
    ../common/optional/gaming-prime.nix
    ../common/optional/logitech.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    ../common/optional/security.nix
    ../common/optional/steam-hardware.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/theme.nix
    ../common/optional/virtualization.nix
    ../common/optional/xremap.nix

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
  };

  # virtualisation.docker.storageDriver = "btrfs";

  system.stateVersion = "22.11";
}
