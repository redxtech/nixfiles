{ pkgs, lib, ... }:

{
  copy-spotify-url = pkgs.callPackage ./copy-spotify-url { };
  home-assistant = pkgs.callPackage ./home-assistant { };
  pipewire-control = pkgs.callPackage ./pipewire-control { };
  pipewire-output-tail = pkgs.callPackage ./pipewire-output-tail { };
  player-mpris-tail = pkgs.callPackage ./player-mpris-tail { };
  polywins = pkgs.callPackage ./polywins { };
  resize-aspect = pkgs.callPackage ./resize-aspect { };
  weather-bar = pkgs.callPackage ./weather-bar { };
}

