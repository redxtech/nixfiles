{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writePython3Bin ? pkgs.writers.writePython3Bin }:

writePython3Bin "weather-bar" {
  libraries = with pkgs.python3Packages; [ requests ];
}

(builtins.readFile ./weather-bar.py)
