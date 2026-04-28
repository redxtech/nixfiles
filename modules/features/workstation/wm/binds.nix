{ inputs, self, ... }:

{
  den.aspects.window-manager-binds.homeManager =
    {
      config,
      pkgs,
      lib,
      host,
      ...
    }:
    {
      programs.niri.settings.binds =
        let
          noctalia =
            cmd:
            [
              "noctalia-shell"
              "ipc"
              "call"
            ]
            ++ (lib.splitString " " cmd);
        in
        lib.mkMerge [
          # launchers
          (
            let
              footclient = "${config.programs.foot.package}/bin/footclient";
              kitty = [
                (lib.getExe config.programs.kitty.package)
                "--single-instance"
              ];
            in
            {
              "Mod+Return".action.spawn = footclient;
              "Mod+Shift+Return".action.spawn = [
                "${footclient}"
                "--app-id=footclient_float"
              ];
              "Mod+Ctrl+Return".action.spawn = kitty;
              "Mod+Ctrl+Shift+Return".action.spawn = kitty ++ [
                "--class"
                "kitty_float"
              ];

              "Mod+W".action.spawn = lib.getExe config.programs.firefox.package;
              "Mod+G".action.spawn = lib.getExe pkgs.nemo-with-extensions;
              "Mod+N".action.spawn = lib.getExe pkgs.obsidian;

              "Mod+Space".action.spawn = noctalia "launcher toggle";
              "Mod+Shift+Space".action.spawn = lib.getExe config.programs.fuzzel.package;
              "Mod+C".action.spawn = noctalia "launcher clipboard";
              "Mod+Ctrl+L".action.spawn = noctalia "lockScreen lock";

              # TODO: add Mod+M for ndrop btop, Mod+N for obsidian, Mod+Shift+W for choose wallpaper
            }
          )

          # system
          {
            "Mod+Backspace".action.spawn = noctalia "sessionMenu toggle";
            "Mod+Shift+E".action.quit = { };
            "Mod+Shift+P".action.power-off-monitors = { };
            "Mod+Shift+Slash".action.show-hotkey-overlay = { };
          }

          # window manipulation
          {
            "Mod+Q".action.close-window = { };

            "Mod+F".action.fullscreen-window = { };
            "Mod+Shift+F".action.toggle-windowed-fullscreen = { };
            "Mod+M".action.maximize-column = { };
            "Mod+Shift+M".action.maximize-window-to-edges = { };
            "Mod+R".action.switch-preset-column-width = { };
            "Mod+Shift+R".action.switch-preset-window-height = { };

            "Mod+S".action.toggle-window-floating = { };
            "Mod+T".action.toggle-column-tabbed-display = { };
            "Mod+Comma".action.consume-window-into-column = { };
            "Mod+Period".action.expel-window-from-column = { };

            "Mod+grave".action.toggle-overview = { };

            # Finer width adjustments.
            # This command can also:
            # * set width in pixels: "1000"
            # * adjust width in pixels: "-5" or "+5"
            # * set width as a percentage of screen width: "25%"
            # * adjust width as a percentage of screen width: "-10%" or "+10%"
            # Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
            # set-column-width "100" will make the column occupy 200 physical screen pixels.
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";

            # Finer height adjustments when in column with other windows.
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

          }

          # navigation
          {
            "Mod+H".action.focus-column-or-monitor-left = { };
            "Mod+J".action.focus-window-or-workspace-down = { };
            "Mod+K".action.focus-window-or-workspace-up = { };
            "Mod+L".action.focus-column-or-monitor-right = { };
            "Mod+Left".action.focus-column-left = { };
            "Mod+Down".action.focus-window-down = { };
            "Mod+Up".action.focus-window-up = { };
            "Mod+Right".action.focus-column-right = { };

            "Mod+Shift+H".action.move-column-left = { };
            "Mod+Shift+J".action.move-window-down-or-to-workspace-down = { };
            "Mod+Shift+K".action.move-window-up-or-to-workspace-up = { };
            "Mod+Shift+L".action.move-column-right = { };
            "Mod+Shift+Left".action.move-column-left = { };
            "Mod+Shift+Down".action.move-window-down = { };
            "Mod+Shift+Up".action.move-window-up = { };
            "Mod+Shift+Right".action.move-column-right = { };

            "Mod+Home".action.focus-column-first = { };
            "Mod+End".action.focus-column-last = { };
            "Mod+Shift+Home".action.move-column-to-first = { };
            "Mod+Shift+End".action.move-column-to-last = { };

            # "Mod+Ctrl+H".action.focus-monitor-left = { };
            # "Mod+Ctrl+J".action.focus-monitor-down = { };
            # "Mod+Ctrl+K".action.focus-monitor-up = { };
            # "Mod+Ctrl+L".action.focus-monitor-right = { };
            "Mod+Ctrl+Left".action.focus-monitor-left = { };
            "Mod+Ctrl+Down".action.focus-monitor-down = { };
            "Mod+Ctrl+Up".action.focus-monitor-up = { };
            "Mod+Ctrl+Right".action.focus-monitor-right = { };

            # "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
            # "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
            # "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
            # "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };
            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };

            "Mod+Page_Down".action.focus-workspace-down = { };
            "Mod+Page_Up".action.focus-workspace-up = { };
            "Mod+U".action.focus-workspace-down = { };
            "Mod+I".action.focus-workspace-up = { };
            "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
            "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

            "Mod+Shift+Page_Down".action.move-workspace-down = { };
            "Mod+Shift+Page_Up".action.move-workspace-up = { };
            "Mod+Shift+U".action.move-workspace-down = { };
            "Mod+Shift+I".action.move-workspace-up = { };

            # You can bind mouse wheel scroll ticks using the following syntax.
            # These binds will change direction based on the natural-scroll setting.
            #
            # To avoid scrolling through workspaces really fast, you can use
            # the cooldown-ms property. The bind will be rate-limited to this value.
            # You can set a cooldown on any bind, but it's most useful for the wheel.
            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = { };
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = { };
            };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-down = { };
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-up = { };
            };

            "Mod+WheelScrollRight".action.focus-column-right = { };
            "Mod+WheelScrollLeft".action.focus-column-left = { };
            "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
            "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
          }

          # You can refer to workspaces by index. However, keep in mind that
          # niri is a dynamic workspace system, so these commands are kind of
          # "best effort". Trying to refer to a workspace index bigger than
          # the current workspace count will instead refer to the bottommost
          # (empty) workspace.
          #
          # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
          # will all refer to the 3rd workspace.

          # indexed workspace binds
          # Mod+[1-9,0] to focus workspace [1-9,10]
          # Mod+Shift+[1-9,0] to move column to workspace [1-9,10]
          (
            let
              indexed = builtins.concatLists (
                builtins.genList (
                  index:
                  let
                    key = toString index;
                    ws = if index == 0 then 10 else index;
                  in
                  [
                    {
                      name = "Mod+${key}";
                      value.action.focus-workspace = ws;
                    }
                    {
                      name = "Mod+Shift+${key}";
                      value.action.move-column-to-workspace = [
                        { focus = false; }
                        ws
                      ];
                    }
                  ]
                ) 10
              );
            in
            builtins.listToAttrs indexed
          )

          # screenshots
          (
            let
              wayshot = lib.getExe pkgs.wayshot;
              path = config.xdg.userDirs.pictures + "/screenshots/$(date +%Y)/$(date +%Y-%m-%d_%H-%M-%S).png";
              toSatty = " | ${lib.getExe pkgs.satty} -f -";
              mkScreenshot =
                {
                  edit ? false,
                  select ? true,
                }:
                let
                  primaryMonitor = lib.head (lib.filter (m: m.primary) host.settings.monitors.monitors);
                  region = if select then "--geometry" else "--output ${primaryMonitor.name}";
                  area = if select then "select" else "monitor";
                  suffix = lib.optionalString edit "-edit";
                  script-name = "screenshot-${area}${suffix}";
                in
                pkgs.writeShellScriptBin script-name ''
                  mkdir -p ${config.xdg.userDirs.pictures}/screenshots/$(date +%Y)
                  ${wayshot} ${region} --clipboard ${path} ${lib.optionalString edit toSatty}
                '';
            in
            {
              "Print".action.spawn-sh = lib.getExe (mkScreenshot { });
              "Mod+Print".action.spawn-sh = lib.getExe (mkScreenshot {
                edit = true;
              });

              "Shift+Print".action.spawn-sh = lib.getExe (mkScreenshot {
                select = false;
              });
              "Mod+Shift+Print".action.spawn-sh = lib.getExe (mkScreenshot {
                select = false;
                edit = true;
              });

              "Ctrl+Print".action.screenshot-screen = { };
              "Alt+Print".action.screenshot-window = { };
            }
          )

          # media
          (
            let
              playerctl = player: action: {
                action.spawn = [
                  (lib.getExe pkgs.playerctl)
                ]
                ++ lib.optional (player != null) "--player=${player}"
                ++ [ action ];
                allow-when-locked = true;
              };
            in
            {
              "XF86AudioPlay" = playerctl "spotify" "play-pause";
              "XF86AudioNext" = playerctl "spotify" "next";
              "XF86AudioPrev" = playerctl "spotify" "previous";

              "Shift+XF86AudioPlay" = playerctl "firefox" "play-pause";
              "Shift+XF86AudioNext" = playerctl "firefox" "next";
              "Shift+XF86AudioPrev" = playerctl "firefox" "previous";

              "Alt+XF86AudioPlay" = playerctl "mpv" "play-pause";
              "Alt+XF86AudioNext" = playerctl "mpv" "next";
              "Alt+XF86AudioPrev" = playerctl "mpv" "previous";

              "Ctrl+XF86AudioPlay" = playerctl null "play-pause";
              "Ctrl+XF86AudioNext" = playerctl null "next";
              "Ctrl+XF86AudioPrev" = playerctl null "previous";

              "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
              "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
              "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
              "XF86AudioMicMute".action.spawn = noctalia "microphone muteInput";
              "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
              "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
            }
          )
        ];
    };
}
