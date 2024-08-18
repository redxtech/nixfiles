{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption;
  cfg = config.desktop.wm;
in {
  options.desktop.wm.rules = with lib.types;
    let
      mkStr = description: example:
        mkOption {
          inherit description example;
          type = str;
          default = "";
        };
      mkBool = description: default:
        mkOption {
          inherit description default;
          type = bool;
          example = toString (!default);
        };
      mkInt = description:
        mkOption {
          inherit description;
          type = nullOr int;
          default = null;
          example = "1";
        };
    in mkOption {
      type = listOf (submodule {
        options = {
          # window selectors
          class = mkStr "Window class" "firefox";
          title = mkStr "Window title" "Firefox";
          initialTitle = mkStr "Initial window title" "Firefox";

          # which workspace/desktop to send the window to
          ws = mkStr "Workspace to send window" "1";
          wsNum = mkInt "Workspace number to send window";

          # window state
          float = mkBool "Float the window" false;
          tile = mkBool "Tile the window" false;
          fullscreen = mkBool "Use fullscreen" false;
          psuedo = mkBool "Use psuedo tiling" false;

          # window flags
          pin = mkBool "Pin the window" false;
          maxSize = mkStr "Max size of the window" "1200 800";
          opacity = mkStr "Opacity of the window" "0.85 0.75";
          follow = mkBool "Focus the window on open" true;
          manage = mkBool "Manage the window" true;
          oneShot = mkBool "If the rule should only be applied once" false;
        };
      });
      default = { };
      description = "The flags to set on the window";
      example = [{
        class = "firefox";
        ws = "www";
      }];
    };

  config = mkIf cfg.enable {
    # TODO: assertions

    # assertions = [ ];
  };
}
