{ inputs, pkgs, lib, config, ... }:

let cfg = config.desktop;
in with lib; {
  options.desktop.wm.binds = with types;
    mkOption {
      type = listOf (submodule {
        options = {
          keys = mkOption {
            type = listOf str;
            default = null;
          };

          cmd = mkOption {
            type = str;
            default = null;
          };

          description = mkOption {
            type = str;
            default = null;
          };

          floating = mkOption {
            type = bool;
            default = false;
          };
        };
      });

      default = [ ];

      example = [{
        keys = [ "Super + Return" ];
        cmd = "kitty";
        description = "Launch terminal";
      }];
    };

  config = mkIf cfg.enable {
    # TODO: assertions

    # assertions = [ ];
  };
}
