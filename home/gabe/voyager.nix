{ inputs, outputs, ... }:
{
  imports = [
    ./global
    # ./features/desktop/wireless
    ./features/games
  ];

  colorscheme = inputs.nix-colors.colorSchemes.atelier-heath;
  wallpaper = outputs.wallpapers.aenami-lunar;

  #   ------
  #  | eDP-1|
  #   ------
  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];
}
