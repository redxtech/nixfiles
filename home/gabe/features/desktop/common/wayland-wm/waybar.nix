{ outputs, config, lib, pkgs, ... }:

let
  # Dependencies
  cat = "${pkgs.coreutils}/bin/cat";
  cut = "${pkgs.coreutils}/bin/cut";
  find = "${pkgs.findutils}/bin/find";
  grep = "${pkgs.gnugrep}/bin/grep";
  pgrep = "${pkgs.procps}/bin/pgrep";
  tail = "${pkgs.coreutils}/bin/tail";
  wc = "${pkgs.coreutils}/bin/wc";
  xargs = "${pkgs.findutils}/bin/xargs";
  timeout = "${pkgs.coreutils}/bin/timeout";
  ping = "${pkgs.iputils}/bin/ping";

  jq = "${pkgs.jq}/bin/jq";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  wofi = "${pkgs.wofi}/bin/wofi";

  # Function to simplify making waybar outputs
  jsonOutput = name: { pre ? "", text ? "", tooltip ? "", alt ? "", class ? "", percentage ? "" }: "${pkgs.writeShellScriptBin "waybar-${name}" ''
    set -euo pipefail
    ${pre}
    ${jq} -cn \
      --arg text "${text}" \
      --arg tooltip "${tooltip}" \
      --arg alt "${alt}" \
      --arg class "${class}" \
      --arg percentage "${percentage}" \
      '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
  ''}/bin/waybar-${name}";

  hasSway = config.wayland.windowManager.sway.enable;
  sway = config.wayland.windowManager.sway.package;
  hasHyprland = config.wayland.windowManager.hyprland.enable;
  hyprland = config.wayland.windowManager.hyprland.package;
in
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or  [ ]) ++ [ "-Dexperimental=true" ];
    });
    systemd.enable = true;
    settings = {
      primary = {
        mode = "dock";
        layer = "top";
        height = 40;
        margin = "6";
        position = "top";
        modules-left = [
          "custom/menu"
        ] ++ (lib.optionals hasSway [
          "sway/workspaces"
          "sway/mode"
        ]) ++ (lib.optionals hasHyprland [
          "hyprland/workspaces"
          "hyprland/submap"
        ]) ++ [
          "custom/currentplayer"
          "custom/player"
        ];

        modules-center = [
          "pulseaudio"
          "battery"
          "clock"
          "custom/unread-mail"
          "custom/gpg-agent"
        ];

        modules-right = [
          "network"
          "custom/tailscale-ping"
          # TODO: currently broken for some reason
          # "custom/gammastep"
          "tray"
          "custom/hostname"
        ];

        clock = {
          interval = 1;
          format = "{:%d/%m %H:%M:%S}";
          format-alt = "{:%Y-%m-%d %H:%M:%S %z}";
          on-click-left = "mode";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "   0%";
          format-icons = {
            headphone = "󰋋";
            headset = "󰋎";
            portable = "";
            default = [ "" "" "" ];
          };
          on-click = pavucontrol;
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰒳";
            deactivated = "󰒲";
          };
        };
        battery = {
          bat = "BAT0";
          interval = 10;
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          onclick = "";
        };
        "sway/window" = {
          max-length = 20;
        };
        network = {
          interval = 3;
          format-wifi = "   {essid}";
          format-ethernet = "󰈁 Connected";
          format-disconnected = "";
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}'';
          on-click = "";
        };
        "custom/tailscale-ping" = {
          interval = 10;
          return-type = "json";
          exec =
            let
              inherit (builtins) concatStringsSep attrNames;
              hosts = attrNames outputs.nixosConfigurations;
              homeMachine = "merope";
              remoteMachine = "alcyone";
            in
            jsonOutput "tailscale-ping" {
              # Build variables for each host
              pre = ''
                set -o pipefail
                ${concatStringsSep "\n" (map (host: ''
                  ping_${host}="$(${timeout} 2 ${ping} -c 1 -q ${host} 2>/dev/null | ${tail} -1 | ${cut} -d '/' -f5 | ${cut} -d '.' -f1)ms" || ping_${host}="Disconnected"
                '') hosts)}
              '';
              # Access a remote machine's and a home machine's ping
              text = "  $ping_${remoteMachine} /  $ping_${homeMachine}";
              # Show pings from all machines
              tooltip = concatStringsSep "\n" (map (host: "${host}: $ping_${host}") hosts);
            };
          format = "{}";
          on-click = "";
        };
        "custom/menu" = {
          return-type = "json";
          exec = jsonOutput "menu" {
            text = "";
            tooltip = ''$(${cat} /etc/os-release | ${grep} PRETTY_NAME | ${cut} -d '"' -f2)'';
          };
          on-click-left = "${wofi} -S drun -x 10 -y 10 -W 25% -H 60%";
          on-click-right = lib.concatStringsSep ";" (
            (lib.optional hasHyprland "${hyprland}/bin/hyprctl dispatch togglespecialworkspace") ++
            (lib.optional hasSway "${sway}/bin/swaymsg scratchpad show")
          );

        };
        "custom/hostname" = {
          exec = "echo $USER@$HOSTNAME";
          on-click = "${systemctl} --user restart waybar";
        };
        "custom/unread-mail" = {
          interval = 5;
          return-type = "json";
          exec = jsonOutput "unread-mail" {
            pre = ''
              count=$(${find} ~/Mail/*/Inbox/new -type f | ${wc} -l)
              if ${pgrep} mbsync &>/dev/null; then
                status="syncing"
              else if [ "$count" == "0" ]; then
                status="read"
              else
                status="unread"
              fi
              fi
            '';
            text = "$count";
            alt = "$status";
          };
          format = "{icon}  ({})";
          format-icons = {
            "read" = "󰇯";
            "unread" = "󰇮";
            "syncing" = "󰁪";
          };
        };
        "custom/gpg-agent" = {
          interval = 2;
          return-type = "json";
          exec =
            let gpgCmds = import ../../../cli/gpg-commands.nix { inherit pkgs; };
            in
            jsonOutput "gpg-agent" {
              pre = ''status=$(${gpgCmds.isUnlocked} && echo "unlocked" || echo "locked")'';
              alt = "$status";
              tooltip = "GPG is $status";
            };
          format = "{icon}";
          format-icons = {
            "locked" = "";
            "unlocked" = "";
          };
          on-click = "";
        };
        "custom/gammastep" = {
          interval = 5;
          return-type = "json";
          exec = jsonOutput "gammastep" {
            pre = ''
              if unit_status="$(${systemctl} --user is-active gammastep)"; then
                status="$unit_status ($(${journalctl} --user -u gammastep.service -g 'Period: ' | ${tail} -1 | ${cut} -d ':' -f6 | ${xargs}))"
              else
                status="$unit_status"
              fi
            '';
            alt = "\${status:-inactive}";
            tooltip = "Gammastep is $status";
          };
          format = "{icon}";
          format-icons = {
            "activating" = "󰁪 ";
            "deactivating" = "󰁪 ";
            "inactive" = "? ";
            "active (Night)" = " ";
            "active (Nighttime)" = " ";
            "active (Transition (Night)" = " ";
            "active (Transition (Nighttime)" = " ";
            "active (Day)" = " ";
            "active (Daytime)" = " ";
            "active (Transition (Day)" = " ";
            "active (Transition (Daytime)" = " ";
          };
          on-click = "${systemctl} --user is-active gammastep && ${systemctl} --user stop gammastep || ${systemctl} --user start gammastep";
        };
        "custom/currentplayer" = {
          interval = 2;
          return-type = "json";
          exec = jsonOutput "currentplayer" {
            pre = ''
              player="$(${playerctl} status -f "{{playerName}}" 2>/dev/null || echo "No player active" | ${cut} -d '.' -f1)"
              count="$(${playerctl} -l 2>/dev/null | ${wc} -l)"
              if ((count > 1)); then
                more=" +$((count - 1))"
              else
                more=""
              fi
            '';
            alt = "$player";
            tooltip = "$player ($count available)";
            text = "$more";
          };
          format = "{icon}{}";
          format-icons = {
            "No player active" = " ";
            "Celluloid" = "󰎁 ";
            "spotify" = "󰓇 ";
            "ncspot" = "󰓇 ";
            "qutebrowser" = "󰖟 ";
            "firefox" = " ";
            "discord" = " 󰙯 ";
            "sublimemusic" = " ";
            "kdeconnect" = "󰄡 ";
            "chromium" = " ";
          };
          on-click = "${playerctld} shift";
          on-click-right = "${playerctld} unshift";
        };
        "custom/player" = {
          exec-if = "${playerctl} status 2>/dev/null";
          exec = ''${playerctl} metadata --format '{"text": "{{title}} - {{artist}}", "alt": "{{status}}", "tooltip": "{{title}} - {{artist}} ({{album}})"}' 2>/dev/null '';
          return-type = "json";
          interval = 2;
          max-length = 30;
          format = "{icon} {}";
          format-icons = {
            "Playing" = "󰐊";
            "Paused" = "󰏤 ";
            "Stopped" = "󰓛";
          };
          on-click = "${playerctl} play-pause";
        };
      };

    };
    # Cheatsheet:
    # x -> all sides
    # x y -> vertical, horizontal
    # x y z -> top, horizontal, bottom
    # w x y z -> top, right, bottom, left
    style = let inherit (config.colorscheme) colors; in /* css */ ''
      * {
        font-family: ${config.fontProfiles.regular.family}, ${config.fontProfiles.monospace.family};
        font-size: 12pt;
        padding: 0 8px;
      }

      .modules-right {
        margin-right: -15px;
      }

      .modules-left {
        margin-left: -15px;
      }

      window#waybar.top {
        opacity: 0.95;
        padding: 0;
        background-color: #${colors.base00};
        border: 2px solid #${colors.base0C};
        border-radius: 10px;
      }
      window#waybar.bottom {
        opacity: 0.90;
        background-color: #${colors.base00};
        border: 2px solid #${colors.base0C};
        border-radius: 10px;
      }

      window#waybar {
        color: #${colors.base05};
      }

      #workspaces button {
        background-color: #${colors.base01};
        color: #${colors.base05};
        padding: 5px 1px;
        margin: 3px 0;
      }
      #workspaces button.hidden {
        background-color: #${colors.base00};
        color: #${colors.base04};
      }
      #workspaces button.focused,
      #workspaces button.active {
        background-color: #${colors.base0A};
        color: #${colors.base00};
      }

      #clock {
        background-color: #${colors.base0C};
        color: #${colors.base00};
        padding-left: 15px;
        padding-right: 15px;
        margin-top: 0;
        margin-bottom: 0;
        border-radius: 10px;
      }

      #custom-menu {
        background-color: #${colors.base0C};
        color: #${colors.base00};
        padding-left: 15px;
        padding-right: 22px;
        margin: 0;
        border-radius: 10px;
      }
      #custom-hostname {
        background-color: #${colors.base0C};
        color: #${colors.base00};
        padding-left: 15px;
        padding-right: 18px;
        margin-right: 0;
        margin-top: 0;
        margin-bottom: 0;
        border-radius: 10px;
      }
      #custom-currentplayer {
        padding-right: 0;
      }
      #tray {
        color: #${colors.base05};
      }
    '';
  };
}
