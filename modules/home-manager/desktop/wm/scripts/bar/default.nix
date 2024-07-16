{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  pipewire = callPackage ./pipewire { };
  pipewire-output-tail = pkgs.callPackage ./pipewire-output-tail { };
  playerctl-tail = callPackage ./playerctl-tail { };
  polywins = callPackage ./polywins { };
  spotify-volume = callPackage ./spotify-volume { };
  weather = callPackage ./weather { };
}

