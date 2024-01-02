{ pkgs, lib, config, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.monitors;
in {
  options.monitors = mkOption {
    type = types.listOf (types.submodule {
      options = {
        name = mkOption {
          type = types.str;
          example = "DP-1";
        };
        primary = mkOption {
          type = types.bool;
          default = false;
        };
        width = mkOption {
          type = types.int;
          example = 1920;
        };
        height = mkOption {
          type = types.int;
          example = 1080;
        };
        rate = mkOption {
          type = types.int;
          default = 60;
        };
        x = mkOption {
          type = types.int;
          default = 0;
        };
        y = mkOption {
          type = types.int;
          default = 0;
        };
        enabled = mkOption {
          type = types.bool;
          default = true;
        };
        workspace = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
    });
    default = [ ];
  };
  config = {
    assertions = [{
      assertion = ((lib.length config.monitors) != 0)
        -> ((lib.length (lib.filter (m: m.primary) config.monitors)) == 1);
      message = "Exactly one monitor must be set to primary.";
    }];
    home.file.".screenlayout" = {
      text = ''
        ${pkgs.xorg.xrandr}/bin/xrandr -- ${
          lib.concatStringsSep " " (builtins.map (m:
            "--output ${m.name} --mode ${toString m.width}x${
              toString m.height
            } --rate ${toString m.rate} --pos ${toString m.x}x${toString m.y} ${
              if m.primary then "--primary" else ""
            } ${if m.enabled then "" else "--off"}") config.monitors)
        }
      '';
      executable = true;
    };
  };
}
