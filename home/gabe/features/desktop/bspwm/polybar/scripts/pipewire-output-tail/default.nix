{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writeScriptBin ? pkgs.writeScriptBin }:

writeScriptBin "pipewire-output-tail"
(builtins.readFile ./pipewire-output-tail.lua)
