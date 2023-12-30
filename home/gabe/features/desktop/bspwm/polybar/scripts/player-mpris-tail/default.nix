{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, writePython3Bin ? pkgs.writers.writePython3Bin }:

writePython3Bin "player-mpris" {
  libraries = with pkgs.python3Packages; [ dbus-python pygobject3 urllib3 ];
}

(builtins.readFile ./player-mpris.py)
