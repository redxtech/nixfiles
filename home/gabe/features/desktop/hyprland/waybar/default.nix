{ pkgs, config, ... }:

{
  programs.waybar = {
    enable = config.wayland.windowManager.hyprland.enabled;

    style = ./style.css;

    # TODO: reference binaries from pkgs
    settings = {
      layer = "top";
      height = 30;
      spacing = 7;
      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "mpris" ];
      modules-right = [
        "custom/weather"
        "wireplumber"
        "memory"
        "cpu"
        "temperature"
        "network"
        "clock"
        "idle_inhibitor"
        "custom/powermenu"
        "tray"
      ];

      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace m-1";
        on-scroll-down = "hyprctl dispatch workspace m+1";
        sort-by-number = true;
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "󰙯";
          "4" = "󰉋";
          "7" = "";
          "8" = "";
          "9" = "󰚺";
          "urgent" = "";
          "default" = "";
        };
        persistent-workspaces = let inherit (builtins) elemAt;
        in {
          "1" = [ "${config.desktop.primaryMonitor}" ];
          "2" = [ "${config.desktop.primaryMonitor}" ];
          "3" = [ "${config.desktop.primaryMonitor}" ];
          "4" = [ "${config.desktop.primaryMonitor}" ];
          "5" = [ "${config.desktop.primaryMonitor}" ];
          "6" = [ "${config.desktop.primaryMonitor}" ];
          "7" = [ "${(elemAt config.desktop.monitors 1).name}" ];
          "8" = [ "${(elemAt config.desktop.monitors 1).name}" ];
          "9" = [ "${(elemAt config.desktop.monitors 1).name}" ];
          "10" = [ "${(elemAt config.desktop.monitors 1).name}" ];
        };
      };

      "hyprland/window" = {
        format = "<span color='#50fa7b'>󰁔</span> {}";
        separate-outputs = true;
      };

      "mpris" = {
        format = "{status_icon} {dynamic} {player_icon}";
        # format = "{status_icon} {artist} - {title} {player_icon}";
        album-len = 0;
        on-click-middle = "~/.local/bin/copy-spotify-share";
        player-icons = {
          default = "󰐊";
          spotify = "";
          chromium = "";
          mpv = "🎵";
        };
        status-icons = {
          playing = "󰏤";
          paused = "󰐊";
        };
        interval = 1;
      };

      wireplumber = {
        format = "{icon} {volume}";
        format-muted = "󰖁 {volume}";
        format-icons = [ "" "" "" ];
        on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = "pavucontrol";
        on-click-middle = "helvum";
      };

      memory = {
        # format = "<span bgcolor='#ff79c6'>󰘚</span> {used:0.1f} GiB",
        format = "󰘚 {used:0.1f} GiB";
        interval = 3;
        on-click = "hyprctl dispatch exec '[floating] kitty -e btop'";
      };

      cpu = {
        # format = "<span bgcolor='#bd93f9'></span> {usage}%";
        "format" = " {usage}%";
        "interval" = 3;
        "tooltip" = false;
        "on-click" = "hyprctl dispatch exec '[floating] kitty -e btop'";
      };

      temperature = {
        critical-threshold = 80;
        # format = "<span bgcolor='#8be9fd'>{icon}</span> {temperatureC}°C";
        format = "{icon} {temperatureC}°C";
        format-icons = [ "󰉬" "" "󰉪" ];
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = "󰈀 {ipaddr}/{cidr}";
        tooltip-format = "󰊗 {ifname} via {gwaddr}";
        format-linked = "󰊗 {ifname} (No IP)";
        format-disconnected = "⚠ Disconnected";
        format-alt =
          " {ifname}: {ipaddr} {bandwidthUpBytes} {bandwidthDownBytes}";
        interval = 5;
        on-click-middle = "nm-connection-editor";
        # on-click-right= "";
      };

      clock = {
        format-alt = "󰅐 {:%H:%M}";
        format-alt = "󰃭 {:%A, %B %d, %Y - %R:%S}";
        tooltip-format = ''
          <big>{:%Y %B}</big>
          <tt><small>{calendar}</small></tt>'';
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          on-click-right = "mode";
          format = {
            months = "<span color='#ffead3'><b>{}</b></span>";
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            weeks = "<span color='#99ffdd'><b>W{}</b></span>";
            weekdays = "<span color='#ffcc66'><b>{}</b></span>";
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
          };
          interval = 1;
        };
        actions = {
          on-click-right = "mode";
          on-click-forward = "tz_up";
          on-click-backward = "tz_down";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰛊";
        };
      };

      tray = { spacing = 10; };

      "custom/media" = {
        exec = "~/.config/waybar/scripts/mediaplayer.py";
        format = "{icon} {}";
        format-icons = {
          playing = "󰏤";
          paused = "󰐊";
        };
        return-type = "json";
        on-click = "playerctl play-pause";
        on-click-middle = "~/.local/bin/copy-spotify-share";
      };

      "custom/pacman" = {
        exec = "~/.config/waybar/scripts/pacman_updates.sh";
        exec-if = "~/.config/waybar/scripts/pacman_updates.sh >/dev/null";
        format = "󰏔 {}";
        interval = 300;
        on-click = ''
          hyprctl dispatch exec "[floating] kitty -e zsh -c 'sudo pacman -Syu && pacaur -Sua; echo Done - Press any key to exit; read -r -n 1'" &'';
      };

      "custom/weather" = {
        exec = "~/.config/waybar/scripts/weather/weather.sh";
        format = "󰖙 {}";
        interval = 60;
      };

      "custom/kde_connect" = {
        exec = "~/.config/waybar/scripts/kde_connect.sh -d";
        format = "󰄡 {}";
        on-click-right = "kdeconnect-app &";
      };

      "custom/do_not_disturb" = {
        format = "{icon}";
        # on-click = "~/.config/rofi/scripts/rofi-powermenu-wl";
        format-icons = {
          enabled = "󰂛";
          disabled = "󰂚";
        };
      };

      "custom/powermenu" = {
        format = "⏻";
        on-click = "~/.config/rofi/scripts/rofi-powermenu-wl &";
      };
    };

    systemd.enable = true;
  };
}
