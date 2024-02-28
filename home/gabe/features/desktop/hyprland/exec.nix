{ inputs, pkgs, ... }:

{
  wayland.windowManager.hyprland = with pkgs; {
    settings = {
      # TODO: add "taskbar" apps to wm-agnostic config
      exec-once = [
        "${waybar}/bin/waybar &"
        "${dunst}/bin/dunst &"
        "${swww}/bin/swww init && ${swww}/bin/swww img ~/Pictures/Wallpaper/new_beginning_4k.png"
        "${libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 &"
        # swayidle / hypridle
        "${pyprland}/bin/pypr &"
        "${dbus}/bin/dbus-update-activation-environment --systemd --all"
        "${systemd}/bin/systemctl --user import-environment QT_QPA_PLATFORMTHEME"
        "${wl-clipboard}/bin/wl-paste --watch cliphist store"
        "${wl-clip-persist}/bin/wl-clip-persist --clipboard regular"
        "${sftpman}/bin/sftpman mount_all &"
        "${udiskie}/bin/udiskie &"

        (writeShellApplication {
          name = "monitor_connection_fix";
          runtimeInputs = [ coreutils socat ];
          text = ''
            handle() {
              case $1 in monitoradded*)
                # reassign monitors
                # hyprctl keyword "monitor" "DP-1,2560x1440,0x0,1"
                # hyprctl keyword "monitor" "DP-2,2560x1440,2560x0,1"

                # loop through workspaces for each monitor and move them to where they should be
                for ws in 1 2 3 4 5 6; do
                  hyprctl dispatch moveworkspacetomonitor $ws 0
                done
                for ws in 7 8 9 10; do
                  hyprctl dispatch moveworkspacetomonitor $ws 1
                done
              esac
            }

            # listen on hyprland sock, send all results to the handle function
            socat - "UNIX-CONNECT:/tmp/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | while read -r line; do handle "$line"; done
          '';
        })

        (writeShellApplication {
          name = "randomize_wallpaper";
          runtimeInputs = [ coreutils swww ];
          text = ''
            WP_DIR="$HOME/Pictures/Wallpaper"

            # This controls (in seconds) when to switch to the next image
            # INTERVAL=3600 # 1 hour
            INTERVAL=1 # 1 hour

            while true; do
            	find "$WP_DIR" |
            		while read -r img; do
            			echo "$((RANDOM % 1000)):$img"
            		done |
            		sort -n | cut -d':' -f2- |
            		while read -r img; do
            			swww img "$img"
            			sleep $INTERVAL
            		done
            done
          '';
        })
      ];
    };
  };
}
