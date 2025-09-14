{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.desktop.wallpaper;
  wm = config.desktop.wm;
in {
  options.desktop.wallpaper = with types; {
    enable = lib.mkEnableOption "Change wallpaper every hour";

    dir = mkOption {
      type = str;
      default = "${config.home.homeDirectory}/Pictures/Wallpaper";
      description = "The directory where wallpapers are stored";
    };
  };

  config = mkIf cfg.enable {
    systemd.user = {
      timers.wallpaper = {
        Unit.Description = "Change wallpaper every hour";
        Timer = {
          Unit = "wallpaper.service";
          OnCalendar = "*:0"; # every hour
        };
        Install = { WantedBy = [ "timers.target" ]; };
      };

      services.wallpaper = {
        Unit = {
          Description = "Change wallpaper to random image";
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Type = "oneshot";
          ExecStart = let
            setWP = pkgs.writeShellApplication {
              name = "set-wallpaper";

              runtimeInputs = with pkgs; [
                betterlockscreen
                coreutils
                findutils
                xorg.xrdb
              ];

              text = ''
                # set wallpaper to a random image
                WP="$(find ${cfg.dir} -type f -iregex ".*\.\(png\|jpe?g\)\$" | shuf -n 1)";

                echo "Setting wallpaper to $WP...";

                # symlink wallpaper to ~/.config/wall.png
                ln -sfT "$WP" "${config.home.homeDirectory}/.config/wall.png"

                # set wallpaper with current wm's wallpaper script
                ${config.desktop.wm.scripts.wm.wallpaper} "$WP" 2>/dev/null

                echo "Wallpaper set to $WP";

                  # prepare lockscreen with betterlockscreen if using bspwm
                ${if wm.wm == "bspwm" then
                  ''betterlockscreen --update "$WP"''
                else
                  ""}
              '';
            };
          in "${setWP}/bin/set-wallpaper";
        };
      };
    };
  };
}
