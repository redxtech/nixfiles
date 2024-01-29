{ pkgs, inputs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.solaar.nixosModules.default

    ./hardware-configuration.nix
    ./filesystem.nix
    ./services.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    ../common/optional/bspwm.nix
    ../common/optional/cockpit.nix
    ../common/optional/containers.nix
    ../common/optional/desktop-apps.nix
    ../common/optional/extra.nix
    ../common/optional/fail2ban.nix
    ../common/optional/flatpak.nix
    ../common/optional/fonts.nix
    # ../common/optional/gaming.nix
    ../common/optional/logitech.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    # ../common/optional/rdp.nix
    ../common/optional/security.nix
    ../common/optional/steam-hardware.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/theme.nix
    ../common/optional/virtualization.nix
    # ../common/optional/xremap.nix
  ];

  networking.hostName = "bastion";

  time.timeZone = "America/Vancouver";

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
    kdeconnect.enable = true;
    solaar.enable = true;
  };

  virtualisation.docker.storageDriver = "btrfs";

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.printing.enable = true;

  services.hardware.openrgb.enable = true;
  hardware = { opengl.enable = true; };

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

      # lossless adapter
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="102b", MODE="0666"

      # This rule was added by Solaar.

      # Allows non-root users to have raw access to Logitech devices.
      # Allowing users to write to the device is potentially dangerous
      # because they could perform firmware updates.
      KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"

      ACTION != "add", GOTO="solaar_end"
      SUBSYSTEM != "hidraw", GOTO="solaar_end"

      # USB-connected Logitech receivers and devices
      ATTRS{idVendor}=="046d", GOTO="solaar_apply"

      # Lenovo nano receiver
      ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6042", GOTO="solaar_apply"

      # Bluetooth-connected Logitech devices
      KERNELS == "0005:046D:*", GOTO="solaar_apply"

      GOTO="solaar_end"

      LABEL="solaar_apply"

      # Allow any seated user to access the receiver.
      # uaccess: modern ACL-enabled udev
      TAG+="uaccess"

      # Grant members of the "plugdev" group access to receiver (useful for SSH users)
      MODE="0660", GROUP="plugdev"
      LABEL="solaar_end"
    '';
  };

  system.stateVersion = "23.11";
}
