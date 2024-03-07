{ lib, config, pkgs, ... }: {
  imports = [
    ../common

    ./default-apps.nix
    ./polybar
    ../rofi
    ./services.nix
  ];
}
