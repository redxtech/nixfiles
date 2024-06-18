{ config, pkgs, lib, ... }:

{
  programs.waybar = let
    pb-scripts = (import
      ../../../../../../home/gabe/features/desktop/bspwm/polybar/scripts) {
        inherit pkgs lib;
      };
    rofi-scripts =
      (import ../../../../../../home/gabe/features/desktop/rofi/scripts) {
        inherit pkgs lib;
      };

    runFloat = "${pkgs.hyprland}/bin/hyprctl dispatch -- exec [float] ";
    kittyRun = "${pkgs.kitty}/bin/kitty --single-instance";
    runHA = "${pb-scripts.home-assistant}/bin/home-assistant";
    runWttr =
      "${pkgs.fish}/bin/fish -c '${pkgs.curl}/bin/curl wttr.in; read -n 1 -p \\\"echo Press any key to continue...\\\"'";
    runPS_MEM =
      "${pkgs.fish}/bin/fish -c 'sudo ${pkgs.ps_mem}/bin/ps_mem; read -s -n 1 -p \\\"echo Press any key to continue...\\\"'";
  in {
    enable = config.wayland.windowManager.hyprland.enable;

    style = ./style.css;

    # TODO: reference binaries from pkgs
    settings.mainBar = {
      layer = "top";
      height = 30;

      spacing = 7;
      modules-left =
        [ "custom/launcher" "hyprland/workspaces" "hyprland/window" ];
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
        "custom/dnd"
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
        persistent-workspaces = let
          primary = (builtins.elemAt config.desktop.monitors 0).name;
          secondary = (builtins.elemAt config.desktop.monitors 1).name;
        in {
          "${primary}" = [ 1 2 3 4 5 6 ];
          "${secondary}" = [ 7 8 9 10 ];
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
        dynamic-len = 35;
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
        format = "{icon} {node_name} {volume}";
        format-muted = "󰖁 {node_name} {volume}";
        format-icons = [ "" "" "" ];
        on-scroll-up =
          "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down =
          "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        on-click =
          "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
        on-click-middle =
          "${pb-scripts.pipewire-control}/bin/pipewire-control next";
      };

      memory = {
        # format = "<span bgcolor='#ff79c6'>󰘚</span> {used:0.1f} GiB",
        format = "󰘚 {used:0.1f} GiB";
        interval = 3;
        on-click = ''${runFloat} "${kittyRun} ${runPS_MEM}"'';
        # on-click = "hyprctl dispatch exec '[floating] kitty -e btop'";
      };

      cpu = {
        # format = "<span bgcolor='#bd93f9'></span> {usage}%";
        format = " {usage}%";
        interval = 3;
        tooltip = false;
        on-click =
          "${pkgs.hyprland}/bin/hyprctl dispatch exec '[floating] kitty -e btop'";
      };

      temperature = {
        critical-threshold = 80;
        # format = "<span bgcolor='#8be9fd'>{icon}</span> {temperatureC}°C";
        format = "{icon} {temperatureC}°C";
        format-icons = [ "󰉬" "" "󰉪" ];
        on-click =
          "${pkgs.hyprland}/bin/hyprctl dispatch exec '[floating] kitty -e btop'";
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = "󰈀 {ifname}";
        tooltip-format = "󰊗 {ifname} via {gwaddr}";
        format-linked = "󰊗 {ifname} (No IP)";
        format-disconnected = "⚠ Disconnected";
        format-alt =
          " {ifname}: {ipaddr} {bandwidthUpBytes} {bandwidthDownBytes}";
        interval = 5;
        on-click-middle =
          "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
        # on-click-right= "";
      };

      clock = {
        format = "󰅐 {:%H:%M}";
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
        on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
        on-click-middle = "${pb-scripts.copy-spotify-url}/bin/copy-spotify-url";
      };

      "custom/weather" = let
        script = pkgs.writers.writePython3 "weather-bar" {
          libraries = with pkgs.python3Packages; [ requests ];
        } (builtins.readFile ./weather-bar.py);
      in {
        # exec = "~/.config/waybar/scripts/weather/weather.sh";
        exec = ''
          OPENWEATHER_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/secrets/openweathermap.txt)" ${script} -u metric'';
        format = "󰖙 {}";
        interval = 600;
        on-click = ''${runFloat} "${kittyRun} ${runWttr}"'';
        on-click-right = "${runHA} light";
        on-click-middle = "${runHA} fan";
      };

      "custom/kde_connect" = {
        exec = "~/.config/waybar/scripts/kde_connect.sh -d";
        format = "󰄡 {}";
        on-click-right = "${pkgs.kdePackages.kdeconnect-kde}kdeconnect-app &";
      };

      "custom/dnd" = let
        toggle = pkgs.writeShellScript "dnd-toggle" ''
          ${pkgs.mako}/bin/makoctl mode -t do-not-disturb
        '';
        # script that uses json return to set alt type to "enabled" or "disabled" based on mako's status
        status = pkgs.writeShellScript "dnd-toggle" ''
          if ${pkgs.mako}/bin/makoctl mode | ${pkgs.ripgrep}/bin/rg --quiet 'do-not-disturb'; then
            echo '{"text": "enabled", "class": "enabled", "percentage": 100, "tooltip": "enabled" }'
          else
            echo '{"text": "disabled", "class": "disabled", "percentage": 0, "tooltip": "disabled" }'
          fi
        '';
      in {
        format = "{icon}";
        exec = "${status}";
        return-type = "json";
        interval = 1;
        on-click = "${toggle}";
        format-icons = [ "󰂚" "󰂛" ];
      };

      "custom/launcher" = {
        format = lib.mkDefault "";
        on-click = "${pkgs.tofi}/bin/tofi-drun";
      };

      "custom/powermenu" = {
        format = "⏻";
        on-click = "~/.config/rofi/scripts/rofi-powermenu-wl &";
        click.left = "${rofi-scripts.rofi-powermenu}/bin/rofi-powermenu";
      };
    };

    systemd.enable = true;
  };
}
