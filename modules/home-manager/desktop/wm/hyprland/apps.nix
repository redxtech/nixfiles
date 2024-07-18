{ config, lib, pkgs, options, ... }:

let
  inherit (lib) mkIf;

  cfg = config.desktop;
  isHyprland = cfg.wm.hyprland.enable;
in {
  config = mkIf isHyprland {
    home.packages = with pkgs; [
      nwg-displays # monitor manager
      satty # image editor
      wdisplays # monitor manager
    ];

    # app launchers
    programs.tofi = {
      enable = true;
      settings = with config.user-theme; {
        drun-launch = true;

        # TODO: switch to nerd font when i make one
        font = "${pkgs.dank-mono}/share/fonts/ttf/DankMono-Regular.ttf";

        text-color = fg;
        prompt-color = purple;
        border-color = purple;
        selection-color = pink;
        background-color = bg;

        width = 720;
        height = 480;

        corner-radius = 10;
      };
    };
    programs.wofi.enable = true;
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Dank Mono:weight=bold:size=24,Symbols Nerd Font:size=24";
          icon-theme = "Papirus-Dark";
        };
        # https://github.com/dracula/fuzzel/blob/main/fuzzel.ini
        colors = {
          background = "282a36dd";
          text = "f8f8f2ff";
          match = "8be9fdff";
          selection-match = "8be9fdff";
          selection = "44475add";
          selection-text = "f8f8f2ff";
          border = "bd93f9ff";
        };
      };
    };

    # logout prompt
    programs.wlogout = {
      enable = true;
      layout = let
        scripts = cfg.wm.scripts.wm;
        height = 0.7;
        width = 0.7;
      in [
        {
          inherit height width;
          action = scripts.lock;
          label = "lock";
          keybind = "l";
          text = "lock";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl hibernate";
          label = "hibernate";
          keybind = "h";
          text = "hibernate";
        }
        {
          inherit height width;
          action = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
          label = "logout";
          keybind = "o";
          text = "logout";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl poweroff";
          label = "shutdown";
          keybind = "p";
          text = "shutdown";
        }
        {
          inherit height width;
          action = scripts.sleep;
          label = "suspend";
          keybind = "s";
          text = "sleep";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl reboot";
          label = "reboot";
          keybind = "r";
          text = "reboot";
        }
      ];
    };

    # image viewer
    programs.imv = {
      enable = true;
      package = pkgs.imv-patched;

      settings = with config.user-theme; {
        options = {
          background = bg;
          overlay_text_color = fg;
          overlay_background_color = bg-alt;
          overlay_font = "Dank Mono:16";
          mouse_wheel = "navigate";
        };
        binds = { };
      };
    };

    xdg.desktopEntries."imv" = {
      name = "Imv";
      genericName = "Image Viewer";
      comment = "Fast freeiamge-based image viewer";
      icon = "multimedia-photo-viewer";
      exec = "${config.programs.imv.package}/bin/imv %U";
      type = "Application";
      categories = [ "Graphics" "2DGraphics" "Viewer" ];
      mimeType = [
        "image/bmp"
        "image/gif"
        "image/jpeg"
        "image/jpg"
        "image/pjpeg"
        "image/png"
        "image/tiff"
        "image/x-bmp"
        "image/x-pcx"
        "image/x-png"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-tga"
        "image/x-xbitmap"
        "image/heif"
        "image/avif"
      ];
    };

    # pdf viewer
    programs.zathura = {
      enable = true;
      extraConfig = ''
        set window-title-basename "true"
        set selection-clipboard "clipboard"

        # dracula color theme
        set notification-error-bg       rgba(255,85,85,1)     # Red
        set notification-error-fg       rgba(248,248,242,1)   # Foreground
        set notification-warning-bg     rgba(255,184,108,1)   # Orange
        set notification-warning-fg     rgba(68,71,90,1)      # Selection
        set notification-bg             rgba(40,42,54,1)      # Background
        set notification-fg             rgba(248,248,242,1)   # Foreground

        set completion-bg               rgba(40,42,54,1)      # Background
        set completion-fg               rgba(98,114,164,1)    # Comment
        set completion-group-bg         rgba(40,42,54,1)      # Background
        set completion-group-fg         rgba(98,114,164,1)    # Comment
        set completion-highlight-bg     rgba(68,71,90,1)      # Selection
        set completion-highlight-fg     rgba(248,248,242,1)   # Foreground

        set index-bg                    rgba(40,42,54,1)      # Background
        set index-fg                    rgba(248,248,242,1)   # Foreground
        set index-active-bg             rgba(68,71,90,1)      # Current Line
        set index-active-fg             rgba(248,248,242,1)   # Foreground

        set inputbar-bg                 rgba(40,42,54,1)      # Background
        set inputbar-fg                 rgba(248,248,242,1)   # Foreground
        set statusbar-bg                rgba(40,42,54,1)      # Background
        set statusbar-fg                rgba(248,248,242,1)   # Foreground

        set highlight-color             rgba(255,184,108,0.5) # Orange
        set highlight-active-color      rgba(255,121,198,0.5) # Pink

        set default-bg                  rgba(40,42,54,1)      # Background
        set default-fg                  rgba(248,248,242,1)   # Foreground

        set render-loading              true
        set render-loading-fg           rgba(40,42,54,1)      # Background
        set render-loading-bg           rgba(248,248,242,1)   # Foreground

        # recolor mode settings
        set recolor-lightcolor          rgba(40,42,54,1)      # Background
        set recolor-darkcolor           rgba(248,248,242,1)   # Foreground

        # startup options
        set adjust-open width
        set recolor true
      '';
    };
  };
}

