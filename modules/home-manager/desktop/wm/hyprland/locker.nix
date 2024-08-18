{ config, lib, ... }:

let
  cfg = config.desktop;

  isHyprland = cfg.wm.hyprland.enable;
in {
  config = lib.mkIf isHyprland {
    programs.hyprlock = let
      monitor = "";
      font_family = "Dank Mono, Symbols Nerd Font";
    in {
      enable = true;

      settings = {
        general = {
          hide_cursor = true;
          grace = 2;
        };

        background = {
          inherit monitor;
          path = "${config.home.homeDirectory}/.config/wall.png";
          color = "rgba(25, 20, 20, 1.0)";

          blur_passes = 2;
          blur_size = 8;
          noise = 1.17e-2;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        };

        input-field = {
          inherit monitor;
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.5)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = true;
          placeholder_text = "";
          hide_input = false;
          position = "0, 50";
          halign = "center";
          valign = "bottom";
        };

        label = [
          # TIME
          {
            inherit font_family monitor;
            text = ''cmd[update:1000] date +"%-I:%M%p"'';
            font_size = 80;
            position = "40, 90";
            halign = "left";
            valign = "bottom";
          }

          # CURRENT SONG
          {
            inherit font_family monitor;
            text =
              "cmd[update:5000] ${cfg.wm.scripts.bar.playerctl-tail} status-once | sed 's/&/&amp;/g'";
            font_size = 20;
            position = "50, 40";
            halign = "left";
            valign = "bottom";
          }
        ];
      };
    };
  };
}
