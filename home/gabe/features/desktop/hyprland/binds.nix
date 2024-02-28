{ inputs, pkgs, ... }:

{
  wayland.windowManager.hyprland = with pkgs; {
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "${kitty}/bin/kitty";
      "$browser" =
        "${firefox-devedition-bin}/bin/firefox-developer-edition -p gabe";
      "$editor" = "${neovim}/bin/nvim";
      "$explorer" = "${cinnamon.nemo-with-extensions}/bin/nemo";
      "$music" = "${spotifywm}/bin/spotifywm";

      bind = let hypr-contrib = inputs.hyprland-contrib.packages.${pkgs.system};
      in [
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

        # selector
        "$mod, Tab, exec, ${pyprland}/bin/pypr expose"

        # lock and sleep
        "$mod SHIFT, L, exec, loginctl lock-session"
        "$mod CTRL, L, exec, loginctl sleep-session"

        # app launchers
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, Return, exec, [floating] $terminal"
        "$mod, SPACE, exec, rofi -show drun"
        "$mod, W, exec, $browser"
        "$mod, F, exec, $explorer"
        "$mod, N, exec, ${neovide}/bin/neovide"

        # terminal apps
        "$mod, U, exec, ${hdrop}/bin/hdrop -b $terminal --class kitty_btop btop"
        "$mod, R, exec, $terminal ranger"
        "$mod SHIFT, N, exec, [floating] $terminal zsh -c 'neofetch && exec zsh'"

        # focus apps

        # rofi
        "$mod SHIFT, E, exec, ~/.config/rofi/scripts/wayland/rofi-powermenu"
        "$mod, Backspace, exec, ~/.config/rofi/scripts/wayland/rofi-powermenu"

        # notifications
        "$mod ALT, H, exec, ${dunst}/bin/dunstctl history-pop"
        "$mod SHIFT ALT, H, exec, ${dunst}/bin/dunstctl close-all"

        # screenshot
        ", Print, exec, ${hypr-contrib.grimblast}/bin/grimblast --notify copy area"
        "SHIFT, Print, exec, ${hypr-contrib.grimblast}/bin/grimblast --notify copy output"
        "$mod, Print, exec, ${hypr-contrib.grimblast}/bin/grimblast --notify save area - | ${swappy}/bin/swappy -f -"
      ] ++ (
        # workspaces
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (builtins.genList (x:
          let
            ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
          in [
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            "$mod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
          ]) 10));

      bindl = let
        pctl = "${playerctl}/bin/playerctl";
        spot = "${pctl} --player=$music";
        chrome = "${pctl} --player=chromium";
        mpv = "${pctl} --player=mpv";
        wp = "${wireplumber}/bin/wpctl";
        volume = ''${wp} set-volume "@DEFAULT_AUDIO_SINK@"'';
        mute = ''${wp} set-mute "@DEFAULT_AUDIO_SINK@" toggle'';
      in [
        # media control
        ", XF86AudioPlay, exec, ${spot} --play-pause"
        ", XF86AudioNext, exec, ${spot} --next"
        ", XF86AudioPrev, exec, ${spot} --previous"

        "SHIFT, XF86AudioPlay, exec, ${chrome} --play-pause"
        "SHIFT, XF86AudioNext, exec, ${chrome} --next"
        "SHIFT, XF86AudioPrev, exec, ${chrome} --previous"

        "ALT, XF86AudioPlay, exec, ${mpv} --play-pause"
        "ALT, XF86AudioNext, exec, ${mpv} --next"
        "ALT, XF86AudioPrev, exec, ${mpv} --previous"

        "CTRL, XF86AudioPlay, exec, ${pctl} --play-pause"
        "CTRL, XF86AudioNext, exec, ${pctl} --next"
        "CTRL, XF86AudioPrev, exec, ${pctl} --previous"

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
