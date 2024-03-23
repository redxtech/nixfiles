{ inputs, pkgs, lib, config, ... }:

{
  imports = [ ./global ./features/desktop/bspwm ];

  # TODO:
  # - improve modularity to allow removal of more features from nixiso

  #  ------
  # | eDP-1|
  #  ------
  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];

  colorscheme = inputs.nix-colors.colorSchemes.dracula;

  # desktop layout
  xsession.windowManager.bspwm = {
    monitors = { "DP-0" = [ "shell" "www" "chat" "music" "files" "video" ]; };
  };

  # laptop only polybar stuff
  services.polybar = {
    script = ''
      polybar main &
    '';

    settings = with builtins;
      with lib.strings; {
        "module/network" = { label.connected.text = "%essid%"; };
      };
  };
}
