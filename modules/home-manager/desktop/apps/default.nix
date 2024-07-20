{ pkgs, lib, config, ... }:

let cfg = config.desktop;
in {
  imports = [
    ./default-apps.nix
    ./firefox
    ./term/alacritty.nix
    ./term/foot.nix
    ./term/kitty.nix
    ./term/rio.nix
    ./feh.nix
    ./mpv.nix
    ./nemo.nix
    ./spotify.nix
    ./thunar.nix
    ./rofi.nix
  ];

  options = let inherit (lib) mkOption types;
  in {
    desktop = {
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

      spicetify.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable spicetify";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        arandr
        # audacity
        beekeeper-studio-ultimate
        betterdiscordctl
        bitwarden-desktop
        deluge
        discord
        dolphin-emu
        ente-desktop
        jellyfin-media-player
        jellyfin-mpv-shim
        kitty
        libreoffice
        multiviewer-for-f1
        neovide
        obsidian
        obsidian-smart-connect
        pavucontrol
        peazip # file archiver
        piper # gui for ratbagd
        planify
        playerctl
        plexamp
        qdirstat
        qimgv
        remmina
        seabird
        slack
        xdragon
        xfce.exo
        xfce.thunar
        xfce.thunar-archive-plugin
        xfce.thunar-volman
        vesktop
        via
        vivaldi
        vlc
        vscodium

        # games
        prismlauncher
      ] ++ config.desktop.apps;

    programs = {
      feh.enable = true;
      zathura.enable = true;
    };

    services.playerctld = { enable = true; };

    # virt-manager autoconnect
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };

    services.flatpak = {
      enable = true;

      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };

      packages = [
        "com.getpostman.Postman"
        "com.obsproject.Studio"
        "io.github.seadve.Kooha"
      ] ++ config.desktop.flatpaks;
    };

    xdg.dataFile."fonts".source = config.lib.file.mkOutOfStoreSymlink
      /run/current-system/sw/share/X11/fonts;
  };
}
