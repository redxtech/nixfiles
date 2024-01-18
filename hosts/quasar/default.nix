{ pkgs, inputs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.hardware.nixosModules.common-pc-ssd

    # TODO: switch to actual configs
    ./hardware-configuration-qemu.nix
    # ./hardware-configuration.nix
    # ./filesystem.nix

    ./services
    # ./acme.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    ../common/optional/containers.nix
    ../common/optional/desktop-apps.nix
    ../common/optional/gnome.nix
    ../common/optional/extra.nix
    ../common/optional/fail2ban.nix
    # ../common/optional/flatpak.nix
    ../common/optional/fonts.nix
    ../common/optional/pipewire.nix
    # ../common/optional/quietboot.nix # TODO: re-enable
    ../common/optional/security.nix
    # ../common/optional/systemd-boot.nix # TODO: re-enable
    ../common/optional/theme.nix
    ../common/optional/virtualization.nix
  ];

  networking.hostName = "quasar";
  nas.enable = true;

  # TODO: remove
  services.qemuGuest.enable = true;
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
  };

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware = { opengl.enable = true; };

  # dbus packages
  services.dbus.packages = with pkgs; [ python310Packages.dbus-python ];

  # ensure gnome settings daemon is running
  services.udev = { packages = with pkgs; [ gnome.gnome-settings-daemon ]; };

  system.stateVersion = "23.11";
}
