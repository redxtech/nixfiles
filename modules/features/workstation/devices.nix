{
  den.aspects.devices = {
    nixos =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      {
        services.udev.packages = with pkgs; [ gnome-settings-daemon ];
        services.udev.extraRules = lib.concatStringsSep "\n" [
          # rules for allowing users in the video group to change the backlight brightness
          ''
            ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${lib.getExe' pkgs.coreutils "chgrp"} video /sys/class/backlight/%k/brightness"
            ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${lib.getExe' pkgs.coreutils "chmod"} g+w /sys/class/backlight/%k/brightness"
          ''

          # rule for via firmware flashing
          ''
            KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
          ''

          # rules for oryx web flashing and live training
          ''
            KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
            KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"
          ''
          # wally flashing rule for the moonlander and planck ez
          ''
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11",     MODE:="0666",     SYMLINK+="stm32_dfu"
          ''

          # rules for lossless adapter
          ''
            SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
            SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="102b", MODE="0666"
          ''
        ];
      };
  };
}
