{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption;
  cfg = config.desktop;
in {
  options.desktop = with lib.types; {
    autolock = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Enable autolocking";
      };

      delay = mkOption {
        type = int;
        default = 600;
        description = "Delay in seconds before autolocking";
      };

      blank = mkOption {
        type = bool;
        default = true;
        description = "Blank the screen before autolocking";
      };
    };
  };

  config = mkIf (cfg.wm.wm == "bspwm") {
    services.xidlehook = {
      enable = true;

      detect-sleep = true;
      not-when-audio = true;
      not-when-fullscreen = true;

      timers = mkIf cfg.autolock.enable ([{
        delay = cfg.autolock.delay;
        command =
          "${pkgs.betterlockscreen}/bin/betterlockscreen --lock dimblur";
      }]
        # blank screen after autolock, if enabled
        ++ lib.optional cfg.autolock.blank {
          delay = cfg.autolock.delay;
          command = "${pkgs.xorg.xset}/bin/xset dpms force off";
        });
    };
  };
}
