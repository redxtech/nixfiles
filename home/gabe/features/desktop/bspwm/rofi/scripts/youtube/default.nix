{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeShellApplication ? pkgs.writeShellApplication }:

with pkgs;
with lib;
writeShellApplication {
  name = "rofi-youtube";
  runtimeInputs = [ choose coreutils curl dunst jq mpv rofi urlencode yt-dlp ];

  text = builtins.readFile ./rofi-youtube.sh;
}
