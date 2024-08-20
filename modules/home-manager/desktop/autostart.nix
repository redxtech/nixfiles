{ pkgs, lib, config, options, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.desktop;
  opt = options.desktop;
in with types; {
  # list of autostart programs
  options.desktop.autostart = {
    run = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of programs to run on every wm startup";
      example = [ "~/.fehbg" "xset r rate 240 50" "gpg-agent --daemon" ];
    };
    runOnce = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of programs to run once at wm startup";
      example = [ "picom" "nm-applet" "blueman-applet" ];
    };
    runWithRule = mkOption {
      type = listOf (submodule {
        options = {
          cmd = mkOption {
            type = str;
            default = null;
          };

          window = mkOption {
            type = str;
            default = null;
            description = "The window to match";
            example = "firefox";
          };

          flags = mkOption {
            type = attrsOf (oneOf [ bool int str ]);
            default = { };
            description = "The flags to set on the window";
            example = {
              state = "floating";
              sticky = true;
              hidden = true;
            };
          };
        };
      });
    };
    runDays = mkOption {
      type = listOf (submodule {
        options = {
          cmd = mkOption {
            type = str;
            description = "The command to run";
            example = "kitty htop";
          };
          days = mkOption {
            type = listOf (ints.between 0 6);
            description =
              "The weekdays on which to run the command. 0 is Monday, 6 is Sunday.";
            example = [ 0 1 2 3 4 ];
          };
        };
      });
      default = [ ];
      description = "List of programs to run on specific weekdays.";
      example = [
        {
          cmd = "slack";
          days = [ 0 1 2 3 4 ];
        }
        {
          cmd = "steam";
          days = [ 5 6 ];
        }
      ];
    };
    processed = mkOption {
      type = listOf str;
      readOnly = true;
      description =
        "Readonly list of pre-processed commands to pass to the wm to run";
    };
  };

  config = lib.mkIf cfg.enable {
    desktop.autostart.processed = let
      inherit (builtins) map;

      joinDays = days: sep: lib.concatStringsSep sep (map toString days);
      runDays = { cmd, days }:
        "${pkgs.writeShellScript "run-${cmd}-on-${joinDays days "-"}" ''
          RUN_DAYS="${joinDays days " "}"
          DATE="$(date +%u)"
          case $RUN_DAYS in 
            *$DATE*)
              ${cmd}
              ;;
          esac
        ''}";
    in map runDays cfg.autostart.runDays;
  };
}

