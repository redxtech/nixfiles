{ lib, config, pkgs, ... }: {
  imports = [
    ../common

    ./default-apps.nix
    ./picom.nix
    ./polybar
    ../rofi
    ./services.nix
  ];
}
