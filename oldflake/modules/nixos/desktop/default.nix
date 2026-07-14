{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.desktop;
  inherit (lib) mkIf mkOption mkEnableOption;
in
{
  imports = [
    ./dm.nix
    ./gaming.nix
    ./wm.nix
  ];

  options.desktop = with lib.types; {
    enable = mkEnableOption "Enable the desktop environment module.";

    isLaptop = mkOption {
      type = bool;
      default = false;
      description = "Enable laptop-specific settings.";
    };
  };

  config =
    let
      inherit (lib) concatStringsSep mkDefault;
    in
    mkIf cfg.enable {
      # font config
      fonts = {
        fontconfig = {
          enable = true;

          defaultFonts = {
            serif = [ "Noto Serif" ];
            sansSerif = [ "Noto Sans" ];
            monospace = [ "Iosevka Custom" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };

        fontDir.enable = true;

        packages =
          with pkgs;
          [
            aporetic-bin
            cantarell-fonts
            dank-mono
            iosevka
            iosevka-custom
            jetbrains-mono
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
          ]
          ++ (with nerd-fonts; [
            fira-code
            hack
            inconsolata
            symbols-only
            noto
          ]);
      };

      # defaults
      programs = {
        dconf.enable = mkDefault true;
        gnupg.agent.enable = true;
        partition-manager.enable = true;
        xfconf.enable = mkDefault true;
      };

      services = {
        printing.enable = mkDefault false;
        ratbagd.enable = mkDefault true;
        upower.enable = mkDefault cfg.isLaptop;
      };

      hardware.graphics.enable = mkDefault true;

      services.auto-cpufreq.enable = mkIf cfg.isLaptop true;
      services.power-profiles-daemon.enable = mkIf cfg.isLaptop false;
      services.tlp.enable = mkIf cfg.isLaptop false;

      # fix for qt6 plugins
      environment.profileRelativeSessionVariables = {
        QT_PLUGIN_PATH = mkDefault [ "/lib/qt-6/plugins" ];
      };

      # dbus packages
      services.dbus.packages = with pkgs; [
        gcr
        python313Packages.dbus-python
      ];

      # udev
      services.udev.packages = with pkgs; [ gnome-settings-daemon ];
      services.udev.extraRules = concatStringsSep "\n" [
        # rules for allowing users in the video group to change the backlight brightness
        ''
          ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
          ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
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
}
