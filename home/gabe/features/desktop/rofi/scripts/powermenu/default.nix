{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
with lib;
writeShellApplication {
  name = "rofi-powermenu";

  runtimeInputs = [ betterlockscreen bspwm coreutils rofi systemd xorg.xset ];

  text = builtins.readFile ./rofi-powermenu.sh;
}
