{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
with lib;
writeShellApplication {
  name = "rofi-clipboard";
  runtimeInputs = [ coreutils gnome.gpaste rofi ];

  text = builtins.readFile ./rofi-clipboard.sh;
}
