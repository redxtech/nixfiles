{ inputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption;
  cfg = config.desktop;
in {
  options.desktop.wm.rules = with lib.types;
    mkOption {
      type = attrsOf (attrsOf (oneOf [ bool int str ]));
      default = { };
      description = "The flags to set on the window";
      example = {
        firefox = {
          sticky = true;
          hidden = true;
          desktop = 2;
        };
        "*:*:Picture-in-Picture" = {
          floating = true;
          sticky = true;
        };
      };
    };

  config = mkIf cfg.enable {
    # TODO: assertions

    # assertions = [ ];
  };
}
