{ pkgs, ... }:

{
  xdg.configFile."hypr/pyprland.toml".source = let toml = pkgs.formats.toml { };
  in (toml.generate "pyprland.toml" {
    pyprland = {
      plugins = [
        "scratchpads"
        # "lost_windows"
        # "monitors"
        # "toggle_dpms"
        # "magnify"
        "expose"
        # "shift_monitors"
        # "workspaces_follow_focus"
      ];
    };

    expose = { include_special = false; };
  });
}
