{ pkgs, ... }:

{
  wayland.windowManager.hyprland = with pkgs; {
    settings = {
      workspace = let inherit (builtins) elemAt;
      in [
        "1,monitor:${config.desktop.primaryMonitor}"
        "2,monitor:${config.desktop.primaryMonitor}"
        "3,monitor:${config.desktop.primaryMonitor}"
        "4,monitor:${config.desktop.primaryMonitor}"
        "5,monitor:${config.desktop.primaryMonitor}"
        "6,monitor:${config.desktop.primaryMonitor}"
        "7,monitor:${(elemAt config.desktop.monitors 1).name}"
        "8,monitor:${(elemAt config.desktop.monitors 1).name}"
        "9,monitor:${(elemAt config.desktop.monitors 1).name}"
        "10,monitor:${(elemAt config.desktop.monitors 1).name}"
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
