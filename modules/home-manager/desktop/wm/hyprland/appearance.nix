{ config, lib, pkgs, options, ... }:

let
  inherit (lib) mkIf;

  cfg = config.desktop.wm.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      general = {
        gaps_in = 7;
        gaps_out = 10;
        border_size = 2;
        # TODO: get from theme
        # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.active_border" = "rgba(8be9fdee) rgba(6c71c4ee) 45deg";
        "col.inactive_border" = "rgba(073642aa)";
      };

      decoration = {
        rounding = 0;

        drop_shadow = "no";

        blur = {
          enabled = "yes";
          size = 8;
          passes = 2;
          ignore_opacity = "yes";
        };
      };

      animations = {
        enabled = "yes";

        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 3, myBezier"
          "windowsOut, 1, 3, default, popin 80%"
          "border, 1, 8, default"
          "borderangle, 1, 6, default"
          "fade, 1, 3, default"
          "workspaces, 1, 3, default"
        ];
      };
    };
  };
}
