{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication, useWayland ? false }:

with pkgs;
with lib;
writeShellApplication {
  name = "rofi-screenshot";
  runtimeInputs =
    [ coreutils flameshot rofi (if useWayland then wl-clipboard else xclip) ];

  text = builtins.readFile ./rofi-screenshot.sh;
}
