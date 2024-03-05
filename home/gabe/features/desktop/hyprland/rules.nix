{ inputs, pkgs, ... }:

{
  wayland.windowManager.hyprland = with pkgs; {
    settings = {
      workspace = [
        "1,monitor:${config.profileVars.primaryMonitor}"
        "2,monitor:${config.profileVars.primaryMonitor}"
        "3,monitor:${config.profileVars.primaryMonitor}"
        "4,monitor:${config.profileVars.primaryMonitor}"
        "5,monitor:${config.profileVars.primaryMonitor}"
        "6,monitor:${config.profileVars.primaryMonitor}"
        "7,monitor:${config.profileVars.secondaryMonitor}"
        "8,monitor:${config.profileVars.secondaryMonitor}"
        "9,monitor:${config.profileVars.secondaryMonitor}"
        "10,monitor:${config.profileVars.secondaryMonitor}"
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
