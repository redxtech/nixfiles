{ pkgs, lib, config, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.desktop;
in with types; {
  # list of monitors & their workspaces
  options.desktop = {
    primaryMonitor = mkOption {
      type = nullOr str;
      readOnly = true;
    };

    enableMonitors = mkOption {
      type = bool;
      default = true;
    };

    monitors = mkOption {
      type = listOf (submodule {
        options = {
          name = mkOption {
            type = str;
            default = null;
          };
          enable = mkOption {
            type = bool;
            default = true;
          };
          primary = mkOption {
            type = bool;
            default = false;
          };
          height = mkOption {
            type = int;
            default = 1080;
          };
          width = mkOption {
            type = int;
            default = 1920;
          };
          rate = mkOption {
            type = int;
            default = 60;
          };
          x = mkOption {
            type = int;
            default = 0;
          };
          y = mkOption {
            type = int;
            default = 0;
          };
          scale = mkOption {
            type = str;
            default = "1";
          };
          hasBar = mkOption {
            type = bool;
            default = true;
          };
          workspaces = mkOption {
            type = listOf (submodule {
              options = {
                number = mkOption {
                  type = int;
                  example = 1;
                  default = 1;
                };
                name = mkOption {
                  type = nullOr str;
                  default = null;
                  example = "home";
                };
                icon = mkOption {
                  type = str;
                  default = "";
                  example = "";
                };
              };
            });
            default = null;
            example = [
              {
                number = 1;
                name = "home";
                icon = "";
              }
              {
                number = 2;
                name = "web";
                icon = "";
              }
              {
                number = 3;
                name = "code";
                icon = "";
              }
            ];
          };
          fingerprint = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
      default = [ ];
      example = [{
        name = "HDMI-1";
        primary = true;
      }];
    };
  };

  config = let
    inherit (lib) head filter length;
    primaryMonitors = (filter (m: m.primary) cfg.monitors);
  in lib.mkIf cfg.enableMonitors {
    # ensure exactly one monitor is set to primary
    assertions = [{
      assertion = ((length cfg.monitors) != 0)
        -> ((length primaryMonitors) == 1);
      message = "Exactly one monitor must be set to primary.";
    }];

    # expose primary monitor name
    desktop.primaryMonitor = (head primaryMonitors).name;

    # autorandr config
    programs.autorandr = let
      inherit (builtins) toString listToAttrs map;

      mkAutorandrConf =
        { name, enable, primary, height, width, rate, x, y, ... }: {
          name = name;
          value = {
            enable = enable;
            primary = primary;
            mode = "${toString width}x${toString height}";
            rate = "${toString rate}.00";
            position = "${toString x}x${toString y}";
          };
        };

      mkAutorandrFingerprint = { name, fingerprint, ... }: {
        name = name;
        value = fingerprint;
      };

      autorandrConf = listToAttrs (map mkAutorandrConf cfg.monitors);
      autorandrFpts = listToAttrs (map mkAutorandrFingerprint cfg.monitors);
    in {
      enable = (length cfg.monitors) != 0;

      profiles.default = {
        config = autorandrConf;
        fingerprint = autorandrFpts;
      };
    };
  };
}

