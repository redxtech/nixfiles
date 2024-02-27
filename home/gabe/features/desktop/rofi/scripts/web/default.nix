{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication, useWayland ? false }:

with pkgs;
with lib;
writeShellApplication {
  name = "rofi-web";
  runtimeInputs = [ coreutils rofi xdg-utils ];

  text = builtins.readFile ./rofi-web.sh;
}
