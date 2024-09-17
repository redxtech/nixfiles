{ config, lib, pkgs, stable, ... }:

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
    ./thunderbird.nix
    ./rofi.nix
    ./zathura.nix
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
        arandr # arrange and resize
        bitwarden-desktop # password manager
        discord # chat app
        feishin # music player
        kooha # simple screen recorder
        libsForQt5.kleopatra # gpg gui
        obsidian # notes app
        pavucontrol # audio control panel
        peazip # file archiver
        piper # gui for ratbagd/logitech mouse control
        postman # api client
        prismlauncher # minecraft launcher
        qdirstat # used storage visualizer
        qimgv # image viewer
        stable.teams-for-linux # microsoft teams (for linux!)
        thunar # file manager
        vesktop # better discord client
        vlc # video player
        warp # file transfer
        xfce.exo # file opener
      ] ++ config.desktop.apps;

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
