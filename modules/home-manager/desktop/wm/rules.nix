{ inputs, pkgs, lib, config, ... }:

let
  cfg = config.desktop.wm;
  inherit (lib.types) attrsOf oneOf bool int str;
in {
  options.desktop.wm.rules = lib.mkOption {
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

  # TODO: assertions
}
