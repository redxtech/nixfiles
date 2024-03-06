{ lib, config, pkgs, ... }: {
  imports = [
    ../common

    ./default-apps.nix
    ./dunst.nix
    ./picom.nix
    ./polybar
    ../rofi
    ./services.nix
  ];
}
