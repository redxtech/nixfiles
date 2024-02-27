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
    ../common/optional/btrfs.nix
    ../common/optional/cockpit.nix
    ../common/optional/containers.nix
    ../common/optional/desktop-apps.nix
    ../common/optional/extra.nix
    ../common/optional/fail2ban.nix
    ../common/optional/flatpak.nix
    ../common/optional/fonts.nix
    ../common/optional/gaming.nix
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
    binfmt.emulatedSystems = [ "aarch64-linux" "x86_64-windows" ];
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
    solaar.enable = true;
    nix-ld.enable = true;
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

  services.udev = {
    # ensure gnome settings daemon is running
    packages = with pkgs; [ gnome.gnome-settings-daemon ];

    extraRules = ''
      # rules for allowing users in the video group to change the backlight brightness
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

      # rules for via firmware flashing
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

      # rules for oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # wally flashing rules for the moonlander and planck ez
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11",     MODE:="0666",     SYMLINK+="stm32_dfu"

      # lossless adapter
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="102b", MODE="0666"

      # solaar

      # allows non-root users to have raw access to logitech devices.
      KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"

      ACTION != "add", GOTO="solaar_end"
      SUBSYSTEM != "hidraw", GOTO="solaar_end"

      ATTRS{idVendor}=="046d", GOTO="solaar_apply" # usb-connected logitech receivers and devices

      ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6042", GOTO="solaar_apply" # lenovo nano receiver

      KERNELS == "0005:046D:*", GOTO="solaar_apply" # bluetooth-connected Logitech devices

      GOTO="solaar_end"

      LABEL="solaar_apply"

      # allow any seated user to access the receiver.
      # uaccess: modern ACL-enabled udev
      TAG+="uaccess"

      # grant members of the "plugdev" group access to receiver (useful for SSH users)
      MODE="0660", GROUP="plugdev"
      LABEL="solaar_end"
    '';
  };

  system.stateVersion = "23.11";
}
