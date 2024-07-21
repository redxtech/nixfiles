{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.desktop.wm;
in {
  imports = [
    ./bspwm
    ./hyprland
    ./scripts

    ./bar/limbo.nix
    ./bar/polybar.nix
    ./bar/waybar/default.nix

    ./binds.nix
    ./rules.nix
    ./wallpaper.nix
  ];

  # TODO:
  # - configure dpms

  options.desktop.wm = with types; {
    enable =
      lib.mkEnableOption "Enable the window manager configuration module";

    wm = mkOption {
      type = nullOr (enum [ "bspwm" "hyprland" ]);
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

  config = lib.mkIf cfg.enable {
    # assertions = [ ];

    # set some xdg user dirs
    xdg = {
      enable = true;

      userDirs = { videos = "$HOME/Videos"; };
    };

    # set gnome to prefer dark theme
    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
  };
}
