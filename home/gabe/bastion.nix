{ inputs, outputs, pkgs, ... }:

{
  imports = [
    ./global
    ./features/desktop/bspwm
    ./features/desktop/common/kdeconnect.nix
  ];

  colorscheme = inputs.nix-colors.colorschemes.dracula;
  wallpaper = outputs.wallpapers.aenami-all-i-need;

  #   -----   ------
  #  | DP-1| | DP-2 |
  #   -----   ------
  monitors = [
    {
      name = "DP-1";
      width = 2560;
      height = 1440;
      refreshRate = 144.0;
      x = 0;
      primary = true;
    }
    {
      name = "DP-2";
      width = 2560;
      height = 1440;
      refreshRate = 144.0;
      x = 2560;
    }
  ];

  xsession.windowManager.bspwm = {
    monitors = {
      "DP-1" = [ "shell" "www" "chat" "files" "five" "six" ];
      "DP-2" = [ "r-www" "music" "video" "ten" ];
    };

    startupPrograms =
      [ "${pkgs.bspwm}/bin/bspc wm --reorder-monitors DP-1 DP-2" ];
  };
}
