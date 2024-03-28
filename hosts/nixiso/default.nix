{ pkgs, config, ... }:

{
  imports = [
    # inputs.nixos-generators.nixosModules.all-formats

    # ./hardware-configuration.nix
    ./desktop-apps.nix
    ./fonts.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    ../common/optional/bspwm.nix
    # ../common/optional/flatpak.nix
    ../common/optional/pipewire.nix
    # ../common/optional/quietboot.nix
    # ../common/optional/systemd-boot.nix
    ../common/optional/theme.nix
  ];

  networking.hostName = "nixiso";

  time.timeZone = "America/Edmonton";

  security.sudo.wheelNeedsPassword = false;

  users.users.gabe.hashedPassword =
    "$6$gNnGxanzppSa/6lj$tTXZwWz4EwglopWxetSpAB9K5Pv.NZUER2bivf7BVFyBywu1bD0bDfTi5/bITG24BOVHIkyk/Y.zXhpOn4d4L1";
  users.users.root.hashedPassword =
    "$6$uDyrFAH9Ss2nivlK$YuCHQMJ1k4bFbTp82mY3D4uJ02WIbSjRJYH4Lt/fbz2ctIMzEavu7hO23Ps4PEM//k8tqmYP7CGO1fIUT56ut0";

  home-manager.users.gabe = import ../../home/gabe/nixiso.nix;

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.touchegg.enable = true;

  system.stateVersion = "23.11";
}
