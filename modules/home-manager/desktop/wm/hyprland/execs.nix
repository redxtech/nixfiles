{ config, pkgs, lib, ... }:

let
  inherit (config.desktop.autostart) run runOnce processed;
  cfg = config.desktop.wm.hyprland;

  mkBG = cmd: "${cmd} &";
  runBG = builtins.map mkBG run;
  runOnceBG = builtins.map mkBG runOnce;
in {
  wayland.windowManager.hyprland = with pkgs;
    lib.mkIf cfg.enable {
      settings = {
        exec = [ "${mako}/bin/mako &" ] ++ runBG;
        exec-once = [
          "${swww}/bin/swww-daemon &"
          "${wl-clipboard}/bin/wl-paste -t text --watch clipman store --no-persist"

          (writeShellApplication {
            name = "monitor_connection_fix";
            runtimeInputs = [ coreutils socat ];
            text = ''
              handle() {
                case $1 in monitoradded*)
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
        ] ++ runOnceBG ++ processed;
      };
    };
}
