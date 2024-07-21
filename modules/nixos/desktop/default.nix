{ pkgs, lib, config, ... }:

let
  cfg = config.desktop;
  inherit (lib) mkIf mkOption mkEnableOption;
in {
  imports = [ ./ai.nix ./dm.nix ./gaming.nix ./wm.nix ];

  options.desktop = with lib.types; {
    enable = mkEnableOption "Enable the desktop environment module.";

    isLaptop = mkOption {
      type = bool;
      default = false;
      description = "Enable laptop-specific settings.";
    };

    apps = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Desktop applications to install";
    };

    useZen = mkOption {
      type = bool;
      default = false;
      description = "Use the zen kernel.";
    };

    useSolaar = mkOption {
      type = bool;
      default = true;
      description = "Install the Solaar package for Logitech devices.";
    };

    remap = mkOption {
      type = bool;
      default = false;
      description = "Remap keys using xremap.";
    };

    remaps = mkOption {
      type = attrsOf str;
      default = { "CapsLock" = "SUPER_L"; };
      description = "Remap keys using xremap.";
    };
  };

  config = let inherit (lib) concatStringsSep mkDefault;

  in mkIf cfg.enable {
    # use zen kernel if enabled
    boot.kernelPackages = mkIf cfg.useZen pkgs.linuxKernel.packages.linux_zen;

    # solaar config
    services.solaar.enable = mkDefault cfg.useSolaar;

    # xremap config
    services.xremap = {
      enable = cfg.remap;
      withX11 = true;
      config.modmap = [{
        name = "Global";
        remap = cfg.remaps;
      }];
    };

    # desktop apps
    environment.systemPackages = with pkgs;
      [
        # gui apps
        firefox-devedition-bin
        flameshot
        gnome.gnome-software
        gpaste
        kitty
        mpv

        # thunar tools
        webp-pixbuf-loader
        poppler
        ffmpegthumbnailer
        freetype
        libgsf
        gnome-epub-thumbnailer

        # theme packages
        catppuccin-sddm-corners
        # sddm-chili-theme

        dracula-theme
        nordzy-cursor-theme
        papirus-icon-theme
        vimix-icon-theme

        # other packages
        fontforge
      ] ++ cfg.apps;

    programs.thunar = {
      enable = true;

      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
    };

    # font config
    fonts = {
      fontconfig = {
        enable = true;

        defaultFonts = {
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "Dank Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };

      fontDir.enable = true;

      packages = with pkgs; [
        cantarell-fonts
        dank-mono
        iosevka
        iosevka-custom
        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "Hack"
            "Inconsolata"
            "JetBrainsMono"
            "NerdFontsSymbolsOnly"
            "Noto"
          ];
        })
        jetbrains-mono
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        noto-fonts-extra
      ];
    };

    # defaults
    programs = {
      adb.enable = mkDefault true;
      dconf.enable = mkDefault true;
      gnupg.agent.enable = true;
      kdeconnect.enable = mkDefault true;
      nix-ld.enable = mkDefault true;
      partition-manager.enable = true;
      xfconf.enable = mkDefault true;
    };

    services = {
      blueman.enable = mkDefault true;
      printing.enable = mkDefault true;
      ratbagd.enable = mkDefault true;
      touchegg.enable = mkDefault cfg.isLaptop;
      tumbler.enable = mkDefault true;
    };

    hardware = {
      bluetooth.enable = mkDefault true;
      bluetooth.powerOnBoot = mkDefault true;
      logitech.wireless.enable = mkDefault true;
      logitech.wireless.enableGraphical = mkDefault true;
      graphics.enable = mkDefault true;
    };

    # audio config (pipewire)
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;

    services.pipewire = {
      enable = mkDefault true;
      alsa.enable = mkDefault true;
      alsa.support32Bit = mkDefault true;
      pulse.enable = mkDefault true;
      # jack.enable = true;
    };

    # fix for qt6 plugins
    environment.profileRelativeSessionVariables = {
      QT_PLUGIN_PATH = mkDefault [ "/lib/qt-6/plugins" ];
    };

    # dbus packages
    services.dbus.packages = with pkgs; [ gcr python310Packages.dbus-python ];

    # udev
    services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    services.udev.extraRules = concatStringsSep "\n" ([
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
    ]);
  };
}
