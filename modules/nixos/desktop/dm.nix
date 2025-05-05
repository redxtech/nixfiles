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
    services = {
      greetd = {
        enable = cfg.dm == "greetd";

        settings = {
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
