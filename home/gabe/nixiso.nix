{ config, pkgs, ... }:

{
  imports = [ ./sops.nix ];

  base.enable = true;
  cli.enable = true;

  home.stateVersion = "24.11";

  programs.firefox.profiles.gabe.extensions.packages =
    with pkgs.nur.repos.rycee.firefox-addons; [
      sidebery
      bitwarden
      ublock-origin
    ];

  programs.kitty = {
    enable = true;

    theme = "Dracula";
    font = {
      name = "Iosevka Custom";
      size = 13;
    };

    settings = {
      cursor_shape = "beam";

      scrollback_lines = 10000;
      scrollback_pager_history_size = 100;

      url_color = "#0087bd";
      url_style = "single";

      repaint_delay = 7;

      enable_audio_bell = false;

      remember_window_size = false;
      initial_window_width = "115c";
      initial_window_height = "30c";

      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_bar_min_tabs = 2;
      tab_activity_symbol = "*";
      tab_title_template = "{index}  {title}";

      active_tab_foreground = "${config.user-theme.fg}";
      active_tab_background = "${config.user-theme.bg}";
      active_tab_font_style = "bold-italic";
      inactive_tab_foreground = "${config.user-theme.fg}";
      inactive_tab_background = "${config.user-theme.bg}";
      inactive_tab_font_style = "normal";

      background_opacity = "0.9";

      editor = "tu";

      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
      shell_integration = "enabled";

      wayland_titlebar_color = "background";
    };

    extraConfig = ''
      modify_font strikethrough_position    130%
      modify_font strikethrough_thickness   0.1px
      modify_font underline_position        150%
      modify_font underline_thickness       0.1px

      # modify_font cell_height               125%
    '';

    shellIntegration.enableZshIntegration = true;
    shellIntegration.enableFishIntegration = true;
    shellIntegration.mode = "enabled";
  };

  programs.mpv = {
    enable = true;

    bindings = {
      a = "vf toggle vflip";
      g = "vf toggle hflip";

      WHEEL_UP = "osd-msg-bar seek -10";
      WHEEL_DOWN = "osd-msg-bar seek 10";
      WHEEL_LEFT = "osd-msg-bar seek -5";
      WHEEL_RIGHT = "osd-msg-bar seek 5";

      ## script binds

      # quality menu
      F =
        "script-binding quality_menu/video_formats_toggle #! Stream Quality > Video";
      "Alt+f" =
        "script-binding quality_menu/audio_formats_toggle #! Stream Quality > Audio";
      "Ctrl+r" = "script-binding quality_menu/reload";

      # webtorrent
      p = "script-binding webtorrent/toggle-info";

      # osc
      tab = "script-binding uosc/toggle-ui";
    };

    config = {
      fs = false;
      autofit-larger = "90%x90%";
      hwdec = "auto";
      volume-max = 250;
      keepaspect = true;
    };

    scripts = with pkgs.mpvScripts; [
      # autocrop
      autoload
      mpris
      quality-menu
      sponsorblock
      thumbfast
      uosc
      webtorrent-mpv-hook
      visualizer
    ];

    scriptOpts = {
      autoload = {
        disabled = false;
        images = false;
        videos = true;
        audio = true;
        ignore_hidden = true;
      };
      uosc = {
        border = "yes";
        top_bar = "always";
        top_bar_controls = "no";
      };
      visualizer = { name = "showwaves"; };
    };
  };

  # set gnome to prefer dark theme
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/shell" = {
        favorite-apps = [
          "firefox-nightly.desktop"
          "kitty.desktop"
          "nemo.desktop"
          "vesktop.desktop"
          "gparted.desktop"
          "org.gnome.Settings.desktop"
        ];
      };
      "org/gnome/desktop/wm/keybindings".close = [ "<Super>q" ];
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
        {
          name = "Launch Terminal";
          binding = "<Super>Return";
          command = "kitty";
        };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" =
        {
          name = "Launch Browser";
          binding = "<Super>w";
          command = "firefox-nightly";
        };
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Iosevka Custom";
      size = 12;
    };
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-xft-antialias=1
        gtk-xft-hinting=1
        gtk-xft-hintstyle=hintfull
        gtk-xft-rgba=rgb
        gtk-button-images=1
        gtk-menu-images=1
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "gtk2";
      package = pkgs.qt6Packages.qt6gtk2;
    };
  };

  home.pointerCursor = {
    name = "Vimix-Cursors";
    package = pkgs.vimix-cursor-theme;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "left_ptr";
    };
  };
}
