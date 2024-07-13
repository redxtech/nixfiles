{ config, pkgs, lib, ... }:

let
  cfg = config.desktop.wm;
  scripts = cfg.scripts;
in {
  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = false;
      # enable = config.wayland.windowManager.hyprland.enable;

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

        "mpris" = let spt-vol = scripts.bar.spotify-volume;
        in {
          format = "{status_icon} {dynamic} {player_icon}";
          dynamic-len = 35;
          dynamic-order = [ "title" "artist" ];
          on-click-middle = scripts.general.copy-spotify-url;
          on-scroll-up = "${spt-vol} +10% &";
          on-scroll-down = "${spt-vol} -10% &";
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
          on-click-middle = "${scripts.bar.pipewire} next";
        };

        memory = {
          # format = "<span bgcolor='#ff79c6'>󰘚</span> {used:0.1f} GiB",
          format = "󰘚 {used:0.1f} GiB";
          interval = 3;
          on-click = scripts.general.ps_mem;
          on-click-right = scripts.general.hdrop-btop;
        };

        cpu = {
          # format = "<span bgcolor='#bd93f9'></span> {usage}%";
          format = " {usage}%";
          interval = 3;
          tooltip = false;
          on-click = scripts.general.hdrop-btop;
        };

        temperature = {
          critical-threshold = 80;
          # format = "<span bgcolor='#8be9fd'>{icon}</span> {temperatureC}°C";
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󰉬" "" "󰉪" ];
          on-click = scripts.general.hdrop-btop;
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
          exec = "${scripts.bar.playerctl-tail} status";
          format = "{}";
          # TODO: add icons, switch script to json return
          # format = "{icon} {}";
          # format-icons = { playing = "󰏤"; paused = "󰐊"; };
          # return-type = "json";
          on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
          on-click-middle = scripts.general.copy-spotify-url;
        };

        "custom/weather" = {
          exec = scripts.bar.weather;
          format = "󰖙 {}";
          interval = 600;
          on-click = scripts.general.wttr;
          on-click-right = "${scripts.general.ha} light";
          on-click-middle = "${scripts.general.ha} fan";
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
          on-click = scripts.launchers.app-launcher;
        };

        "custom/powermenu" = {
          format = "⏻";
          on-click = scripts.launchers.powermenu;
        };
      };

      systemd.enable = true;
    };
  };
}
