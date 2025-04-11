{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.desktop;
in {
  options.desktop = let inherit (lib) mkOption types;
  in with types; {
    dm = mkOption {
      type = enum [ "greetd" "gdm" ];
      default = if cfg.wm == "gnome" then "gdm" else "greetd";
      defaultText =
        ''if config.desktop.wm == "gnome" then "gdm" else "greetd"'';
      description = ''
        The display manager to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.regreet = {
      enable = cfg.dm == "greetd";

      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = "Vimix-cursors";
        package = pkgs.vimix-cursors;
      };

      settings = {
        GTK = {
          application_prefer_dark_theme = true;
          theme_name = "Dracula";
        };

        background = {
          fit = "Cover";
          path = let
            bg = pkgs.fetchurl {
              name = "all-i-need-4k.png";
              url =
                "https://slink.super.fish/image/4885fd3a-f8a8-4a81-9d4d-74cf04521b0c.png";
              hash = "sha256-+4JR/SQ9yKLiiwEpe9arfnuvyVOq0xyLIGioaso6gIU=";
            };
          in "${bg}";
        };
      };
    };

    services = {
      greetd = {
        enable = true;
        # for tuigreet, disable regreet to use
        settings = mkIf (!config.programs.regreet.enable) {
          default_session = {
            command = let
              hyprland =
                config.programs.uwsm.waylandCompositors.hyprland.binPath;
            in ''
              ${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd "uwsm start -S -F ${hyprland}"
            '';
            user = "greeter";
          };
        };
      };

      # set gdm to use wayland
      xserver.displayManager.gdm.wayland = true;
    };
  };
}
