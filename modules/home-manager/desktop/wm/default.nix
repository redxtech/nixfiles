{ inputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.desktop.wm;
in with types; {
  imports = [
    ./bspwm
    # ./hyprland

    ./binds.nix
    ./rules.nix
  ];

  # TODO:
  # - configure notif daemon
  # - set relavant polybar config ?
  # - configure autolocking
  # - configure dpms

  options.desktop.wm = {
    enable =
      lib.mkEnableOption "Enable the window manager configuration module";

    wm = mkOption {
      type = enum [ "bspwm" "hyprland" ];
      default = null;
      description = ''
        The window manager to use.
      '';
    };

    isLaptop = mkOption {
      type = bool;
      default = false;
      description = "Whether the system is a laptop";
    };

    autolock = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Whether to enable autolocking";
      };

      timeout = mkOption {
        type = int;
        default = 600;
        description = "The time in seconds before the screen is locked";
      };
    };
  };

  # config = lib.mkIf cfg.enable { assertions = [ ]; };
}
