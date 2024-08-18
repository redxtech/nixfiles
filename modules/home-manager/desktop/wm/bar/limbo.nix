{ config, pkgs, lib, ... }:

let
  cfg = config.desktop;
  inherit (cfg.wm) scripts;
  inherit (lib) mkIf optional;
in {
  config = mkIf cfg.wm.enable {
    services.limbo = let colours = config.user-theme;
    in {
      enable = true;

      settings = {
        theme.font = "Dank Mono";

        bar = {
          theme = {
            inherit (colours) bg fg;
            sectionBg = colours.bgAlt;
          };
          modules = {
            left = [ "app-launcher" "notifications" ]
              ++ optional (!cfg.isLaptop) "todo" ++ [ "music" ];
            center = [ "workspaces" ];
            right = [ "sysmon" "quick-settings" ]
              ++ optional cfg.isLaptop "battery" ++ [ "clock" ];
          };
          appLauncher = {
            icon = { color = colours.fg; };
            onPrimaryClick = "${pkgs.fuzzel}/bin/fuzzel";
          };
          battery = {
            rampIcons = with colours; [
              {
                name = "battery-4";
                color = green;
              }
              {
                name = "battery-3";
                color = green;
              }
              {
                name = "battery-2";
                color = yellow;
              }
              {
                name = "battery-1";
                color = red;
              }
            ];
            chargingIcon.color = colours.green;
          };
          clock.icon.color = colours.green;
          notifications = {
            segments = [ "weather" "todoist" "github" ];
            weather = {
              icon = {
                color = with colours; {
                  day = yellow;
                  night = blue;
                  rain = blue;
                  snow = fg;
                  fog = blue;
                  wind = fg;
                  cloud = blue;
                  error = red;
                };
              };
            };
            todoist.icon.color = colours.red;
            github.icon.color = colours.fg;
          };
          quickSettings = {
            segments = [
              "tray"
              "night-light"
              "caffeine"
              "brightness"
              "dnd"
              "mic"
              "volume"
              "network"
              "toggle"
            ];
            tray.ignoredApps = [ "KDE Connect Indicator" "Sunshine" ];
            nightLight = {
              dayIcon.color = colours.blue;
              nightIcon.color = colours.yellow;
            };
            brightness = {
              rampIcons = [
                {
                  name = "brightness-down";
                  color = colours.yellow;
                }
                {
                  name = "brightness-half";
                  color = colours.yellow;
                }
                {
                  name = "brightness-up";
                  color = colours.yellow;
                }
              ];
              step = 5.0e-2;
              onPrimaryClick = "${scripts.general.ha} light";
              onSecondaryClick = "${scripts.general.ha} fan";
            };
            caffeine = {
              icon = { color = colours.blue; };
              activeIcon.color = colours.cyan;
              toggleCmd = "${pkgs.wlinhibit}/bin/wlinhibit";
            };
            dnd = {
              icon.color = colours.red;
              dndIcon.color = colours.blue;
              toggleCmd = "${pkgs.mako}/bin/makoctl mode -t do-not-disturb";
              statusCmd = "${pkgs.mako}/bin/makoctl mode";
              historyCmd = "${pkgs.mako}/bin/makoctl restore";
              dismissCmd = "${pkgs.mako}/bin/makoctl dismiss";
            };
            mic = {
              icon.color = colours.orange;
              muteIcon.color = colours.blue;
              onSecondaryClick = "${pkgs.pavucontrol}/bin/pavucontrol --tab=4";
            };
            volume = {
              rampIcons = [
                {
                  name = "volumes-3";
                  color = colours.red;
                }
                {
                  name = "volume-2";
                  color = colours.red;
                }
                {
                  name = "volume";
                  color = colours.red;
                }
              ];
              muteIcon.color = colours.blue;
              headphonesRamp = [
                {
                  name = "headphones-off";
                  color = colours.red;
                }
                {
                  name = "headphones";
                  color = colours.red;
                }
              ];
              headphonesMute.color = colours.blue;
            };
            network = {
              rampIcons = with colours; [
                {
                  name = "wifi";
                  color = blue;
                }
                {
                  name = "wifi-2";
                  color = blue;
                }
                {
                  name = "wifi-1";
                  color = blue;
                }
              ];
              offIcon = {
                name = "wifi-off";
                color = colours.red;
              };
              ethernetIcon.color = colours.cyan;
              ethernetOffIcon.color = colours.red;
              onPrimaryClick =
                "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
            };
            battery = {
              rampIcons = with colours; [
                {
                  name = "battery-4";
                  color = green;
                }
                {
                  name = "battery-3";
                  color = green;
                }
                {
                  name = "battery-2";
                  color = green;
                }
                {
                  name = "battery-1";
                  color = yellow;
                }
                {
                  name = "battery";
                  color = red;
                }
              ];
              chargingIcon.color = colours.green;
            };
            toggle = {
              icon.color = colours.fg;
              openIcon.color = colours.fg;
            };
          };
          sysmon = {
            onPrimaryClick = scripts.general.hdrop-btop;
            onSecondaryClick = scripts.general.ps_mem;
            cpu.icon.color = colours.pink;
            ram.icon.color = colours.purple;
            temp = {
              icon.color = colours.red;
              path = cfg.hardware.cpuTempPath;
            };
          };
          todo.icon.color = colours.red;
          twitch.channels = [ "Wirtual" "Wirtual2" "btssmash" ];
          workspaces = {
            monitors = if (!cfg.isLaptop) then [
              { workspaces = [ 1 2 3 4 5 6 ]; }
              { workspaces = [ 7 8 9 10 ]; }
            ] else [{
              workspaces = [ 1 2 3 4 5 6 7 8 9 10 ];
            }];
            color = {
              active = colours.cyan;
              hasWindows = colours.cyan;
              normal = colours.blue;
            };
          };
        };
      };
    };
  };
}
