{ inputs, outputs, ... }:
{
  imports = [
    ./global
    # ./features/desktop/hyprland
    # ./features/desktop/wireless
    ./features/games
  ];

  wallpaper = outputs.wallpapers.aenami-lunar;
  colorscheme = inputs.nix-colors.colorSchemes.atelier-heath;

  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];
}
