{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
writeShellApplication {
  name = "resize-aspect";
  runtimeInputs = [ bc bspwm jq ];

  text = builtins.readFile ./resize-aspect.sh;
}
