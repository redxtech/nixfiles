{ config, pkgs, lib, ... }:

let
  cfg = config.desktop.wm;
  scripts = cfg.scripts;
in {
  wayland.windowManager.hyprland = with pkgs;
    lib.mkIf cfg.hyprland.enable {
      settings = {
        "$mod" = "SUPER";
        "$terminal" = "${kitty}/bin/kitty";
        "$browser" =
          "${firefox-devedition-bin}/bin/firefox-developer-edition -p gabe";
        "$editor" = "${neovim-nightly}/bin/nvim";
        "$explorer" = "${cinnamon.nemo-with-extensions}/bin/nemo";
        "$music" = "${config.programs.spicetify.spicedSpotify}/bin/spotify";

        # TODO: get binds from config.desktop.wm.binds
        bind = [
          # hyprland
          "$mod, Q, killactive"
          "$mod ALT, Q, exit"
          "$mod, M, exec, hyprctl keyword general:layout master"
          "$mod SHIFT, M, exec, hyprctl keyword general:layout dwindle"
          "$mod CTRL, M, layoutmsg, orientationnext"

          # move focus with super + arrow keys
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"
          "$mod ALT, J, cyclenext, prev"
          "$mod ALT, K, cyclenext"
          "$mod, grave, focuscurrentorlast"
          "$mod, Tab, workspace, previous"

          # move windows
          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
          "$mod SHIFT ALT, J, swapnext, prev"
          "$mod SHIFT ALT, K, swapnext"

          # state flags
          "$mod, S, togglefloating"
          "$mod, Y, pin"
          "$mod, F, fullscreen"
          "$mod SHIFT, F, fakefullscreen"
          "$mod CTRL, J, togglesplit" # dwindle only
          "$mod, P, pseudo" # dwindle only
          "$mod, V, togglespecialworkspace, hidden"
          "$mod SHIFT, V, movetoworkspacesilent, special:hidden"

          # scroll through workspaces
          "$mod, mouse_down, workspace, m-1"
          "$mod, mouse_up, workspace, m+1"
          "$mod, bracketleft, workspace, m-1"
          "$mod, bracketright, workspace, m+1"

          # lock and sleep
          "$mod SHIFT, L, exec, loginctl lock-session"
          "$mod CTRL, L, exec, loginctl sleep-session"

          # app launchers
          "$mod, Return, exec, $terminal"
          "$mod SHIFT, Return, exec, [floating] $terminal"
          "CTRL, Return, exec, ${pkgs.foot}/bin/footclient"
          "$mod, SPACE, exec, ${scripts.rofi.app-launcher}"
          "$mod, W, exec, $browser"
          "$mod, G, exec, $explorer"
          "$mod SHIFT, N, exec, ${neovide}/bin/neovide"

          # terminal apps
          "$mod, M, exec, ${scripts.general.hdrop-btop}"
          "$mod, N, exec, ${hdrop}/bin/hdrop -c obsidian ${pkgs.obsidian}/bin/obsidian"
          "$mod, R, exec, $terminal --class kitty_float ranger"

          # stuff
          "$mod, C, exec, ${cfg.scripts.general.clipboard}"

          # focus apps

          # rofi
          "$mod SHIFT, E, exec, ${cfg.scripts.wm.powermenu}"
          "$mod, Backspace, exec, ${cfg.scripts.wm.powermenu}"

          # notifications
          "$mod ALT, H, exec, ${dunst}/bin/dunstctl history-pop"
          "$mod SHIFT ALT, H, exec, ${dunst}/bin/dunstctl close-all"

          # screenshot
          ", Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy area"
          "SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify save area - | ${satty}/bin/satty -f -"
          "CTRL, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy output - | ${satty}/bin/satty -f -"
          "$mod, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify save output - | ${satty}/bin/satty -f -"
        ] ++ (
          # workspaces
          # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (x:
            let
              ws = let c = (x + 1) / 10;
              in builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
            ]) 10));

        bindl = let
          pctl = "${playerctl}/bin/playerctl";
          spot = "${pctl} --player=spotify";
          # chrome = "${pctl} --player=chromium";
          firefox = "${pctl} --player=firefox";
          mpv = "${pctl} --player=mpv";
          wp = "${wireplumber}/bin/wpctl";
          volume = ''${wp} set-volume "@DEFAULT_AUDIO_SINK@"'';
          mute = ''${wp} set-mute "@DEFAULT_AUDIO_SINK@" toggle'';
        in [
          # media control
          ", XF86AudioPlay, exec, ${spot} play-pause"
          ", XF86AudioNext, exec, ${spot} next"
          ", XF86AudioPrev, exec, ${spot} previous"

          "SHIFT, XF86AudioPlay, exec, ${firefox} play-pause"
          "SHIFT, XF86AudioNext, exec, ${firefox} next"
          "SHIFT, XF86AudioPrev, exec, ${firefox} previous"

          "ALT, XF86AudioPlay, exec, ${mpv} play-pause"
          "ALT, XF86AudioNext, exec, ${mpv} next"
          "ALT, XF86AudioPrev, exec, ${mpv} previous"

          "CTRL, XF86AudioPlay, exec, ${pctl} play-pause"
          "CTRL, XF86AudioNext, exec, ${pctl} next"
          "CTRL, XF86AudioPrev, exec, ${pctl} previous"

          # volume
          ", XF86AudioRaiseVolume, exec, ${volume} 5%+"
          ", XF86AudioLowerVolume, exec, ${volume} 5%-"
          ", XF86AudioMuteVolume, exec, ${mute}"
        ];

        bindm = [
          # move & resize windows
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };
}
