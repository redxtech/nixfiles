{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable rec {
    home.packages = with pkgs; [ vimix-cursor-theme ];

    fontProfiles = {
      enable = true;

      monospace = {
        family = "Iosevka Custom";
        package = pkgs.iosevka-custom;
      };

      regular = {
        family = "Noto Sans";
        package = pkgs.noto-fonts;
      };

      symbols = {
        family = "Nerd Fonts Symbols";
        package =
          pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; };
      };

      extraFonts = with pkgs; [
        cantarell-fonts
        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "Hack"
            "Inconsolata"
            "Iosevka"
            # "JetBrainsMono"
            "NerdFontsSymbolsOnly"
            "Noto"
          ];
        })
        inter
        iosevka-comfy.comfy
        jetbrains-mono
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        noto-fonts-extra
        xkcd-font
      ];
    };

    gtk = {
      enable = true;

      font = {
        name = config.fontProfiles.regular.family;
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

      gtk3 = { extraConfig = { gtk-application-prefer-dark-theme = 1; }; };

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

    services.xsettingsd = {
      enable = true;
      settings = {
        "Net/ThemeName" = "${gtk.theme.name}";
        "Net/IconThemeName" = "${gtk.iconTheme.name}";
      };
    };

    xresources.properties = with config.user-theme; {
      "*.foreground" = fg;
      "*.background" = bg;
      "*.color0" = color0;
      "*.color8" = color8;
      "*.color1" = color1;
      "*.color9" = color9;
      "*.color2" = color2;
      "*.color10" = color10;
      "*.color3" = color3;
      "*.color11" = color11;
      "*.color4" = color4;
      "*.color12" = color12;
      "*.color5" = color5;
      "*.color13" = color13;
      "*.color6" = color6;
      "*.color14" = color14;
      "*.color7" = color7;
      "*.color15" = color15;
    };
  };
}
