{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
writeShellApplication {
  name = "pipewire-control";
  runtimeInputs = [ choose coreutils ripgrep sd wireplumber ];

  text = builtins.readFile ./pipewire-control.sh;
}
