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

    # app launchers
    programs.tofi = {
      enable = true;
      settings = with config.user-theme; {
        drun-launch = true;

        # TODO: switch to nerd font when i make one
        font = "${pkgs.dank-mono}/share/fonts/ttf/DankMono-Regular.ttf";

        text-color = fg;
        prompt-color = purple;
        border-color = purple;
        selection-color = pink;
        background-color = bg;

        width = 720;
        height = 480;

        corner-radius = 10;
      };
    };
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
    programs.wofi.enable = true;

    # logout prompt
    programs.wlogout = {
      enable = true;
      layout = let
        scripts = cfg.wm.scripts.wm;
        height = 0.7;
        width = 0.7;
      in [
        {
          inherit height width;
          action = scripts.lock;
          label = "lock";
          keybind = "l";
          text = "lock";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl hibernate";
          label = "hibernate";
          keybind = "h";
          text = "hibernate";
        }
        {
          inherit height width;
          action = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
          label = "logout";
          keybind = "o";
          text = "logout";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl poweroff";
          label = "shutdown";
          keybind = "p";
          text = "shutdown";
        }
        {
          inherit height width;
          action = scripts.sleep;
          label = "suspend";
          keybind = "s";
          text = "sleep";
        }
        {
          inherit height width;
          action = "${pkgs.systemd}/bin/systemctl reboot";
          label = "reboot";
          keybind = "r";
          text = "reboot";
        }
      ];
    };
  };
}

