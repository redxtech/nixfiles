{ lib, config, pkgs, ... }: {
  imports = [
    ../common

    ./polybar
    ../rofi
    ./services.nix
  ];
}
