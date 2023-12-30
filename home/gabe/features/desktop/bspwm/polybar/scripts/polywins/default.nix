{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writePython3Bin ? pkgs.writers.writePython3Bin }:

writePython3Bin "polywins" { libraries = with pkgs.python3Packages; [ ]; }

(builtins.readFile ./polywins.py)
