{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  pipewire = callPackage ./pipewire { };
  playerctl-tail = callPackage ./playerctl-tail { };
  spotify-volume = callPackage ./spotify-volume { };
  weather = callPackage ./weather { };
}

