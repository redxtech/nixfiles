{ pkgs, inputs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-7590-nvidia

    ./hardware-configuration.nix
    ./filesystem.nix
    ./services.nix

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
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    ../common/optional/security.nix
    ../common/optional/steam-hardware.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/theme.nix
    ../common/optional/virtualization.nix

  ];

  networking.hostName = "voyager";

  time.timeZone = "America/Edmonton";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      # "i686-linux" 
      "x86_64-windows"
    ];
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = false;
  };

  # virtualisation.docker.storageDriver = "btrfs";

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.printing.enable = true;

  hardware = { opengl.enable = true; };

  services.touchegg.enable = true;

  # dbus packages
  services.dbus.packages = with pkgs; [ python310Packages.dbus-python ];

  # ensure gnome settings daemon is running
  services.udev = {
    packages = with pkgs; [ gnome.gnome-settings-daemon ];
    # udev rules for moonlander flashing
    extraRules = ''
      # rules for allowing users in the video group to change the backlight brightness
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # Wally Flashing rules for the Moonlander and Planck EZ
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11",     MODE:="0666",     SYMLINK+="stm32_dfu"
    '';
  };

  system.stateVersion = "22.11";
}
