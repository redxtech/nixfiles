{ pkgs, lib, config, ... }:

let cfg = config.desktop;
in {
  imports = [
    ./firefox
    ./kitty.nix
    ./mpv.nix
    ./rio.nix
    # more
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
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        arandr # TODO: move to xorg config
        # audacity
        beekeeper-studio-ultimate
        betterdiscordctl
        deluge
        discord
        dolphin-emu
        jellyfin-media-player
        jellyfin-mpv-shim
        kitty
        libreoffice
        multiviewer-for-f1
        neovide
        pavucontrol
        planify
        playerctl
        plexamp
        qdirstat
        remmina
        seabird
        slack
        spotifywm
        xdragon
        xfce.exo
        xfce.thunar
        xfce.thunar-archive-plugin
        xfce.thunar-volman
        vesktop
        via
        vivaldi
        vlc

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

      packages = [ "com.getpostman.Postman" "com.obsproject.Studio" ]
        ++ config.desktop.flatpaks;
    };

    xdg.dataFile."fonts".source = config.lib.file.mkOutOfStoreSymlink
      /run/current-system/sw/share/X11/fonts;

    xdg.portal = {
      enable = true;

      extraPortals = with pkgs; [ xdg-desktop-portal ];
      xdgOpenUsePortal = false;

      config = { common.default = "*"; };
    };
  };
}
