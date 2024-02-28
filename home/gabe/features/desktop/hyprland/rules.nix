{ inputs, pkgs, ... }:

{
  wayland.windowManager.hyprland = with pkgs; {
    settings = {
      workspace = [
        "1,monitor:DP-1"
        "2,monitor:DP-1"
        "3,monitor:DP-1"
        "4,monitor:DP-1"
        "5,monitor:DP-1"
        "6,monitor:DP-1"
        "7,monitor:DP-2"
        "8,monitor:DP-2"
        "9,monitor:DP-2"
        "10,monitor:DP-2"
      ];

      windowrule = [
        "tile,^(firefox-aurora).*$"
        "workspace 2,^(firefox-aurora).*$"

        "float,title:^(Picture in picture)$"
        "pin,title:^(Picture in picture)$"
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"

        "workspace 3,^(discord)$"
        "noinitialfocus,^(discord)$"

        "workspace 3,^(Element)$"

        "tile,^(Spotify)$"
        "workspace 8,^(Spotify)$"

        "opacity 0.85 0.75, ^(nemo)$"
        "float,^(Bitwarden)$"
      ];

      layerrule = [ "blur,waybar" "blur,notifications" ];
    };
  };
}
