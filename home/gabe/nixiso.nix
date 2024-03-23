{ inputs, pkgs, lib, config, ... }:

{
  imports = [ ./global ./features/desktop/bspwm ];

  # TODO:
  # - improve modularity to allow removal of more features from nixiso

  # desktop layout
  xsession.windowManager.bspwm = {
    monitors = { "DP-0" = [ "shell" "www" "chat" "music" "files" "video" ]; };
  };
}
