{ lib, ... }:
let
  workspaces =
    (map toString (lib.range 0 9)) ++
    (map (n: "F${toString n}") (lib.range 1 12));
  # Map keys to hyprland directions
  directions = rec {
    left = "l"; right = "r"; up = "u"; down = "d";
    h = left; l = right; k = up; j = down;
  };
in {
  wayland.windowManager.hyprland.settings = {
    bindm = [
      "SUPER,mouse:272,movewindow"
      "SUPER,mouse:273,resizewindow"
    ];

    bind = [
      "SUPERSHIFT,q,killactive"
      "SUPERSHIFT,e,exit"

      "SUPER,s,togglesplit"
      "SUPER,f,fullscreen,1"
      "SUPERSHIFT,f,fullscreen,0"
      "SUPERSHIFT,space,togglefloating"

      "SUPER,minus,splitratio,-0.25"
      "SUPERSHIFT,minus,splitratio,-0.3333333"

      "SUPER,equal,splitratio,0.25"
      "SUPERSHIFT,equal,splitratio,0.3333333"

      "SUPER,g,togglegroup"
      "SUPER,t,lockactivegroup,toggle"
      "SUPER,apostrophe,changegroupactive,f"
      "SUPERSHIFT,apostrophe,changegroupactive,b"

      "SUPER,u,togglespecialworkspace"
      "SUPERSHIFT,u,movetoworkspacesilent,special"
    ] ++
    # Change workspace
    (map (n:
      "SUPER,${n},workspace,name:${n}"
    ) workspaces) ++
    # Move window to workspace
    (map (n:
      "SUPERSHIFT,${n},movetoworkspacesilent,name:${n}"
    ) workspaces) ++
    # Move focus
    (lib.mapAttrsToList (key: direction:
      "SUPER,${key},movefocus,${direction}"
    ) directions) ++
    # Swap windows
    (lib.mapAttrsToList (key: direction:
      "SUPERSHIFT,${key},swapwindow,${direction}"
    ) directions) ++
    # Move windows
    (lib.mapAttrsToList (key: direction:
      "SUPERCONTROL,${key},movewindoworgroup,${direction}"
    ) directions) ++
    # Move monitor focus
    (lib.mapAttrsToList (key: direction:
      "SUPERALT,${key},focusmonitor,${direction}"
    ) directions) ++
    # Move workspace to other monitor
    (lib.mapAttrsToList (key: direction:
      "SUPERALTSHIFT,${key},movecurrentworkspacetomonitor,${direction}"
    ) directions);
  };
}
