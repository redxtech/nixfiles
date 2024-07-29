{ config, pkgs, lib, ... }:

let
  cfg = config.desktop.wm;
  scripts = cfg.scripts;
in {
  config = lib.mkIf cfg.bspwm.enable {
    services.polybar = let
      inherit (builtins) concatStringsSep elemAt length;
      inherit (config.desktop) isLaptop;
      inherit (lib) optionals mkIf;

      multiMonitor = length config.desktop.monitors > 1;
      getMon = i: (elemAt config.desktop.monitors i);
      barFont = config.fontProfiles.monospace.family;
    in with config.user-theme; {
      enable = lib.mkIf config.desktop.wm.wm == "bspwm";

      package = pkgs.polybarFull;

      script = ''
        polybar main &

        ${if multiMonitor then "polybar secondary &" else ""}
      '';

      settings = let
        runFloat = window:
          "${pkgs.bspwm}/bin/bspc rule -a ${window} -o state=floating; ";
        kittyRun =
          "${runFloat "kitty"} ${pkgs.kitty}/bin/kitty --single-instance";
        runBtop = "${kittyRun} ${pkgs.btop}/bin/btop";
        runSlurm =
          "${kittyRun} -o initial_window_width=79c -o initial_window_height=22c ${pkgs.slurm-nm}/bin/slurm -i ${config.desktop.hardware.network.interface}";
        runHA = scripts.general.ha;

        isWired = (config.desktop.hardware.network.type == "wired");

        baseModules = [ "weather" "margin" ]
          ++ (optionals isLaptop [ "backlight" "margin" ]) ++ [
            # "kdeconnect"
            # "margin"
            "pipewire"
            "margin"
            "memory"
            "margin"
            "temperature"
            "margin"
            "cpu"
            "margin"
            "network"
            "margin"
          ] ++ (optionals isLaptop [ "battery" "margin" ])
          ++ [ "date" "margin" "dnd" ];
      in {
        "colours" = {
          # named colours
          bg = bg;
          bg-alt = bg-alt;
          fg = fg;
          fg-alt = fg-alt;
          blue = blue;
          cyan = cyan;
          green = green;
          orange = orange;
          pink = pink;
          purple = purple;
          red = red;
          yellow = yellow;

          trans = "#00000000";
          semi-trans-black = "#aa000000";

          # module colours
          backlight = yellow;
          caffeine = yellow;
          cpu = purple;
          date = green;
          dnd = cyan;
          icon-menu = blue;
          kdeconnect = cyan;
          memory = pink;
          mpris = green;
          network = blue;
          powermenu = red;
          temperature = orange;
          updates = purple;
          weather = yellow;
          volume = orange;
        };
        "bar/main" = {
          width = "100%";
          height = 32;
          line-size = 2;
          offset.y = 0;
          bottom = false;
          fixed-center = true;
          wm-restack = "bspwm";
          override-redirect = false;
          enable-ipc = true;

          background = bg;
          foreground = fg;

          cursor = {
            click = "pointer";
            scroll = "ns-resize";
          };

          font = [
            # standard text fonts
            "${barFont}:style=Regular:weight=100:size=11;3"
            "${barFont}:style=Bold:size=11;3"
            "${barFont}:style=Italic:size=11;3"

            # icon fonts
            "Symbols Nerd Font Mono:style=Regular:size=10;2"
            "Symbols Nerd Font Mono:style=Regular:size=12;2"
            "Symbols Nerd Font Mono:style=Regular:size=8;2"
          ];

          modules = {
            left = concatStringsSep " " [
              "icon-menu"
              "margin"
              "bspwm"
              "polywins"
              # "todo"
            ];
            center =
              concatStringsSep " " [ "playerctl-tail" "playerctl-tail-icon" ];
            right = concatStringsSep " "
              (baseModules ++ [ "margin" "tray" "margin" ]);
          };
        };
        "bar/secondary" = mkIf multiMonitor {
          inherit (config.services.polybar.settings."bar/main")
            width height line-size offset bottom fixed-center wm-restack
            override-redirect enable-ipc background foreground cursor font;

          monitor = "${(getMon 1).name}";

          modules = {
            left =
              concatStringsSep " " [ "bspwm" "margin" "polywins-secondary" ];
            center = config.services.polybar.settings."bar/main".modules.center;
            right =
              concatStringsSep " " (baseModules ++ [ "margin" "powermenu" ]);
          };
        };
        "settings" = { screenchange-reload = true; };
        # modules
        "module/backlight" = mkIf isLaptop {
          type = "internal/backlight";

          card = config.desktop.hardware.backlightCard;

          enable-scroll = true;
          scroll-interval = -10;

          format = {
            underline = "\${colours.backlight}";
            prefix = {
              text = "󰖨";
              background = "\${colours.backlight}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%percentage%%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/battery" = mkIf isLaptop {
          type = "internal/battery";

          battery = config.desktop.hardware.battery.device;
          adapter = config.desktop.hardware.battery.adapter;
          full-at = config.desktop.hardware.battery.full-at;

          format = {
            charging = {
              text = "<label-charging>";
              underline = "\${colours.cyan}";
              prefix = {
                text = "󰂄";
                background = "\${colours.cyan}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
            discharging = {
              text = "<label-discharging>";
              underline = "\${colours.cyan}";
              prefix = {
                text = "󰁾";
                background = "\${colours.cyan}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
            full = {
              text = "<label-full>";
              underline = "\${colours.green}";
              prefix = {
                text = "󰁹";
                background = "\${colours.green}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
          };
          label = {
            charging = {
              text = "%percentage%%";
              background = "\${colours.bg-alt}";
              padding = 1;
            };
            discharging = {
              text = "%percentage%%";
              background = "\${colours.bg-alt}";
              padding = 1;
            };
            full = {
              text = "%percentage%%";
              background = "\${colours.bg-alt}";
              padding = 1;
            };
          };
        };
        "module/icon-menu" = {
          type = "custom/text";
          click = { left = "${pkgs.rofi}/bin/rofi -show drun"; };
          label = lib.mkDefault "";
          format = {
            text = "<label>";
            background = "\${colours.icon-menu}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/bspwm" = {
          type = "internal/bspwm";

          format.text = "<label-state> <label-mode>";

          label = {
            focused = {
              text = "%icon%";
              foreground = "\${colours.green}";
              padding = 2;
            };
            occupied = {
              text = "%icon%";
              foreground = "\${colours.purple}";
              padding = 2;
            };
            urgent = {
              text = "%icon%";
              foreground = "\${colours.red}";
              padding = 2;
            };
            empty = {
              text = "%icon%";
              foreground = "\${colours.blue}";
              padding = 2;
            };
            locked = {
              text = "󰍁";
              foreground = "\${colours.yellow}";
              padding = 1;
            };
            sticky = {
              text = "󰐃";
              foreground = "\${colours.yellow}";
              padding = 1;
            };
            private = {
              text = "󰒃";
              foreground = "\${colours.red}";
              padding = 1;
            };
            marked = {
              text = "󰃃";
              foreground = "\${colours.green}";
              padding = 1;
            };
          };
          ws-icon = [
            "shell;"
            "www;"
            "chat;󰙯"
            "files;󰉋"
            "r-www;"
            "music;󰓇"
            "video;󰚺"
          ];
          ws.icon.default = "";
        };
        "module/cpu" = {
          type = "internal/cpu";

          interval = 1;
          format = {
            text = "<label>%{A}";
            underline = "\${colours.cpu}";
            prefix = {
              text = lib.mkDefault "%{A1:${runBtop}:}󰍛";
              background = "\${colours.cpu}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%percentage:2%%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/date" = {
          type = "internal/date";

          time = "%H:%M";
          time-alt = "%a, %b %d %H:%M:%S";

          format = {
            text = "<label>";
            underline = "\${colours.date}";
            prefix = {
              text = "󰅐";
              background = "\${colours.date}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%time%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/dnd" = {
          type = "custom/ipc";

          initial = 1;

          hook = [
            ''
              echo "%{A1:${pkgs.dunst}/bin/dunstctl set-paused true && ${pkgs.polybar}/bin/polybar-msg hook dnd 2:}󰂚%{A}" &''
            ''
              echo "%{A1:${pkgs.dunst}/bin/dunstctl set-paused false && ${pkgs.polybar}/bin/polybar-msg hook dnd 1:}󰂛%{A}" &''
          ];

          format = {
            background = "\${colours.dnd}";
            foreground = "\${colours.bg}";
            padding = 1;
          };
        };
        # TODO: fix this
        "module/kdeconnect" = {
          type = "custom/script";

          exec =
            "${config.xdg.configHome}/polybar/scripts/kdeconnect/polybar-kdeconnect.sh -d";
          tail = true;

          click.right = "${pkgs.libsForQt5.kdeconnect-kde}/bin/kdeconnect-app&";

          format = {
            underline = "\${colours.kdeconnect}";
            prefix = {
              background = "\${colours.kdeconnect}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
            label = {
              text = "";
              background = "\${colours.bg-alt}";
              foreground = "\${colours.fg}";
              padding = 1;
            };
          };
        };
        "module/margin" = {
          type = "custom/text";

          format = {
            text = "%{T1} %{T-}";
            foreground = "\${colours.trans}";
          };
        };
        "module/memory" = {
          type = "internal/memory";

          interval = 3;
          format = {
            text = "<label>%{A}";
            underline = "\${colours.memory}";
            prefix = {
              text = lib.mkDefault "%{A1:${scripts.general.ps_mem}:}󰘚";
              background = "\${colours.memory}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%used%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/playerctl-tail" = let pctl = scripts.bar.playerctl-tail;
        in {
          type = "custom/script";

          exec = "${pctl} status";
          tail = true;

          click = {
            left = "${pctl} play-pause &";
            right = "${pctl} next &";
            middle = scripts.general.copy-spotify-url;
          };

          scroll = let spt-vol = scripts.bar.spotify-volume;
          in {
            up = "${spt-vol} +10% &";
            down = "${spt-vol} -10% &";
          };

          format = {
            underline = "\${colours.mpris}";
            prefix = {
              text = "󰝚";
              background = "\${colours.mpris}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            # text = "%output:0:40:...%";
            text = "%output%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/playerctl-tail-icon" = let
          pctl = scripts.bar.playerctl-tail;
          pctl-tail = config.services.polybar.settings."module/playerctl-tail";
        in {
          inherit (pctl-tail) type tail click scroll;

          exec = "${pctl} icon";

          format = { inherit (pctl-tail.format) underline; };
          label = {
            inherit (pctl-tail.label) text background foreground;
            padding.right = 1;
          };
        };
        "module/network" = {
          type = "internal/network";

          interval = 3;
          interface-type = config.desktop.hardware.network.type;

          animation-packetloss = [ (if isWired then "󰌙" else "󰤮") "" ];
          animation.packetloss = {
            foreground = "\${colours.red}";
            background = "\${colours.bg-alt}";
            padding.right = 1;
            framerate = 500;
          };
          ramp-signal = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];

          format = let icon = if isWired then "󰈀" else "󰖩";
          in {
            connected = {
              text = if isWired then
                "<label-connected>%{A}"
              else
              # "<label-connected><ramp-signal>%{A}";
                "<label-connected>%{A}";
              underline = "\${colours.network}";
              prefix = {
                text = "%{A1:${runSlurm}:}${icon}";
                background = "\${colours.network}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
            disconnected = {
              text = "<label-disconnected>%{A}";
              underline = "\${colours.network}";
              prefix = {
                text = "%{A1:${runSlurm}:}${icon}";
                background = "\${colours.network}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
            packetloss = {
              text = "<label-packetloss><animation-packetloss>%{A}";
              underline = "\${colours.network}";
              prefix = {
                text = "%{A1:${runSlurm}:}${icon}";
                background = "\${colours.network}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
          };
          label = {
            connected = {
              text = (if isWired then "%ifname% %netspeed:07%" else "%essid%");
              background = "\${colours.bg-alt}";
              foreground = "\${colours.fg}";
              padding = 1;
            };
            disconnected = {
              text = "%ifname% not connected";
              background = "\${colours.bg-alt}";
              foreground = "\${colours.fg}";
              padding = 1;
            };
            packetloss = {
              text = "%ifname% dropping packets";
              background = "\${colours.bg-alt}";
              foreground = "\${colours.red}";
              padding = 1;
            };
          };
        };
        "module/pipewire" = {
          type = "custom/script";

          tail = true;
          exec = scripts.bar.pipewire-output-tail;

          click = {
            left = "${scripts.bar.pipewire} toggle-mute";
            right = "${
                runFloat "Pavucontrol"
              } exec ${pkgs.pavucontrol}/bin/pavucontrol &";
            middle = "${scripts.bar.pipewire} next";
          };

          scroll = {
            up = "${scripts.bar.pipewire} volume up";
            down = "${scripts.bar.pipewire} volume down";
          };

          format = {
            text = "<label>";
            underline = "\${colours.volume}";
            prefix = {
              text = "󰕾";
              background = "\${colours.volume}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%output:0:20:...%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/polywins" = {
          type = "custom/script";

          tail = true;

          exec = "${scripts.bar.polywins} ${config.desktop.primaryMonitor}";

          format = "<label>";
          label = {
            text = "%output%";
            padding = 1;
          };
        };
        "module/polywins-secondary" = mkIf multiMonitor {
          inherit (config.services.polybar.settings."module/polywins")
            format label tail type;

          exec = "${scripts.bar.polywins} ${(getMon 1).name}";
        };
        "module/powermenu" = {
          type = "custom/text";

          click.left = "${scripts.wm.powermenu}/bin/rofi-powermenu";

          label = "⏻";
          format = {
            text = "<label>";
            background = "\${colours.powermenu}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
        "module/temperature" = {
          type = "internal/temperature";

          interval = 5;
          warn-temperature = 80;
          hwmon-path = config.desktop.hardware.cpuTempPath;

          format = {
            text = "<label>%{A}";
            underline = "\${colours.temperature}";
            prefix = {
              text = lib.mkDefault "%{A1:${runBtop}:}󰔏";
              background = "\${colours.temperature}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
            warn = {
              text = "<label-warn>";
              underline = "\${colours.red}";
              prefix = {
                text = lib.mkDefault "%{A1:${runBtop}:}󰸁";
                background = "\${colours.red}";
                foreground = "\${colours.bg}";
                padding = 1;
              };
            };
          };
          label = {
            text = "%temperature-c%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
            warn = {
              text = "%temperature-c%";
              background = "\${colours.bg-alt}";
              foreground = "\${colours.fg}";
              padding = 1;
            };
          };
        };
        "module/todo" = {
          type = "custom/script";

          exec =
            "${pkgs.todoist}/bin/todoist list --filter 'today & !#daily' | ${pkgs.gawk}/bin/awk '{print substr($0, index($0, $6)) \" -> \" $4}'";
          interval = 60;

          format = "<label>";
          label = {
            text = "%output%";
            padding = 1;
          };
        };
        "module/tray" = {
          type = "internal/tray";

          tray = {
            size = 22;
            padding = 2;
            background = "\${colours.bg}";
          };
        };
        "module/weather" = {
          type = "custom/script";

          interval = 600;
          exec = ''
            OPENWEATHER_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/secrets/openweathermap.txt)" ${scrips.bar.weather}/bin/weather-bar -u metric'';

          format = {
            underline = "\${colours.weather}";
            text = "<label>%{A}%{A}%{A}";
            prefix = {
              text =
                "%{A1:${scripts.general.wttr}:}%{A3:${runHA} light:}%{A2:${runHA} fan:}󰅟";
              background = "\${colours.weather}";
              foreground = "\${colours.bg}";
              padding = 1;
            };
          };
          label = {
            text = "%output:0:8:...%";
            background = "\${colours.bg-alt}";
            foreground = "\${colours.fg}";
            padding = 1;
          };
        };
      };
    };

    # polybar seems to start before bspwm is ready, so we need to restart it
    systemd.user.services.polybar-restart = {
      Service.Type = "oneshot";
      Service.ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
      Service.ExecStart =
        "${pkgs.systemd}/bin/systemctl --user restart polybar.service";
      Unit.After = [ "tray.target" ];
      Install.WantedBy = [ "tray.target" ];
    };
  };
}

