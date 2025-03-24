{ config, lib, pkgs, options, ... }:

let
  inherit (lib) mkIf;

  cfg = config.desktop;
  isHyprland = cfg.wm.hyprland.enable;
in {
  config = mkIf isHyprland {
    home.packages = with pkgs; [
      nwg-displays # monitor manager
      satty # image editor
      wdisplays # monitor manager
    ];

    # app launcher
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Dank Mono:weight=bold:size=24,Symbols Nerd Font:size=24";
          icon-theme = "Papirus-Dark";
        };
        # https://github.com/dracula/fuzzel/blob/main/fuzzel.ini
        colors = {
          background = "282a36dd";
          text = "f8f8f2ff";
          match = "8be9fdff";
          selection-match = "8be9fdff";
          selection = "44475add";
          selection-text = "f8f8f2ff";
          border = "bd93f9ff";
        };
      };
    };
  };
}

