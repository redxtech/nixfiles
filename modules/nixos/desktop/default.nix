{ inputs, pkgs, lib, config, ... }:

let
  cfg = config.desktop;
  inherit (lib) mkIf mkOption mkEnableOption;
in {
  imports = [
    inputs.solaar.nixosModules.default
    inputs.xremap-flake.nixosModules.default

    ./gaming.nix
  ];

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

    flatpaks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Flatpaks to install";
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

    remaps = mkOption {
      type = attrsOf str;
      default = { "CapsLock" = "SUPER_L"; };
      description = "Remap keys using xremap.";
    };
  };

  config = let inherit (lib) concatStringsSep mkDefault optional;

  in mkIf cfg.enable {
    # use zen kernel if enabled
    boot.kernelPackages = mkIf cfg.useZen pkgs.linuxKernel.packages.linux_zen;

    # solaar config
    programs.solaar.enable = mkDefault cfg.useSolaar;

    # xremap config
    services.xremap = {
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
        gnome.gpaste
        kitty
        logiops
        mpv
        obsidian
        piper
        spotifywm
        vivaldi
        vscodium

        # thunar tools
        webp-pixbuf-loader
        poppler
        ffmpegthumbnailer
        freetype
        libgsf
        gnome-epub-thumbnailer

        # theme packages
        catppuccin-sddm-corners
        sddm-chili-theme

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

    # flatpak config
    services.flatpak = {
      enable = true;

      packages = cfg.flatpaks;

      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal ];
      config = { common.default = "*"; };
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
    programs.adb.enable = mkDefault true;
    programs.dconf.enable = mkDefault true;
    programs.gnupg.agent.enable = true;
    programs.kdeconnect.enable = mkDefault true;
    programs.nix-ld.enable = mkDefault true;
    programs.partition-manager.enable = true;
    programs.xfconf.enable = mkDefault true;
    services.blueman.enable = mkDefault true;
    services.hardware.openrgb.enable = mkDefault true;
    services.printing.enable = mkDefault true;
    services.ratbagd.enable = mkDefault true;
    services.touchegg.enable = mkDefault cfg.isLaptop;
    hardware.bluetooth.enable = mkDefault true;
    hardware.bluetooth.powerOnBoot = mkDefault true;
    hardware.logitech.wireless.enable = mkDefault true;
    hardware.logitech.wireless.enableGraphical = mkDefault true;
    hardware.opengl.enable = mkDefault true;

    # audio config (pipewire)
    sound.enable = true;
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # jack.enable = true;
    };

    # fix for qt6 plugins
    environment.profileRelativeSessionVariables = {
      QT_PLUGIN_PATH = mkDefault [ "/lib/qt-6/plugins" ];
    };

    # dbus packages
    services.dbus.packages = with pkgs; [ python310Packages.dbus-python ];

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
    ] ++ (optional cfg.useSolaar ''
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
    ''));
  };
}
