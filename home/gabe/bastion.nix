{ inputs, outputs, ... }:

{
  imports = [
    ./global
    # ./features/desktop/bspwm
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
}
