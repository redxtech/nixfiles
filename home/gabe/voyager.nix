{ inputs, outputs, pkgs, lib, config, ... }:

{
  imports = [
    ./global
    ./features/desktop/bspwm
    ./features/desktop/bspwm/per-device/voyager.nix
  ];

  colorscheme = inputs.nix-colors.colorSchemes.atelier-heath;
  wallpaper = outputs.wallpapers.aenami-lunar;

  #   ------
  #  | eDP-1|
  #   ------
  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];

  # desktop layout
  xsession.windowManager.bspwm = {
    monitors = { "eDP-1" = [ "shell" "www" "chat" "music" "files" "video" ]; };
  };

  # laptop only polybar stuff
  services.polybar = {
    script = ''
      polybar main &

      MONITOR_COUNT=$(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.ripgrep}/bin/rg ' connected' | ${pkgs.coreutils}/bin/wc -l)

      if test "$MONITOR_COUNT" = "2"; then
        polybar secondary &
      fi
    '';

    settings = with builtins;
      with lib.strings; {
        "bar/secondary" = {
          inherit (config.services.polybar.settings."bar/main")
            width height line-size offset bottom fixed-center wm-restack
            override-redirect enable-ipc background foreground cursor font;

          monitor = "DP-1";

          modules = {
            left =
              concatStringsSep " " [ "bspwm" "margin" "polywins-secondary" ];
            center = config.services.polybar.settings."bar/main".modules.center;
            right = concatStringsSep " " (config.device-vars.barRightModules
              ++ [ "margin" "tray" "margin" "powermenu" ]);
          };
        };
        "module/polywins-secondary" = {
          inherit (config.services.polybar.settings."module/polywins")
            format label tail type;

          exec = let
            polywins =
              pkgs.callPackage ./features/desktop/bspwm/polybar/scripts/polywins
              { };
          in "${polywins}/bin/polywins DP-2";
        };
        "module/backlight" = {
          type = "internal/backlight";

          card = "intel_backlight";
          enable-scroll = true;
          scroll-interval = -10;

          format = {
            underline = "\${colours.backlight";
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
        "module/battery" = {
          type = "internal/battery";

          battery = "BAT0";
          adapter = "AC";
          full-at = 98;

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
        "module/network" = { label.connected.text = "%essid%"; };
      };
  };

  xdg.configFile."wireplumber/main.lua.d/51-alsa-rename.lua".text = ''
    table.insert(alsa_monitor.rules, {
      matches = { { { "node.name", "matches", "alsa_output.pci-0000_00_1f.3.*" } } },
      apply_properties = { ["node.description"] = "Speakers" },
    })

    table.insert(alsa_monitor.rules, {
      matches = { { { "node.name", "matches", "alsa_output.usb-AudioQuest_AudioQuest_DragonFly_Red*" } } },
      apply_properties = { ["node.description"] = "DAC" },
    })
  '';
}
