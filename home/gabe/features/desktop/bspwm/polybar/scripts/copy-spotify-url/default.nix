{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
with lib;
writeShellApplication {
  name = "copy-spotify-url";
  runtimeInputs = [ choose coreutils playerctl ripgrep xclip ];

  text = builtins.readFile ./copy-spotify-url.sh;
}
