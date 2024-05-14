{ pkgs, lib, ... }:

{
  copy-spotify-url = pkgs.callPackage ./copy-spotify-url { };
  home-assistant = pkgs.callPackage ./home-assistant { };
  pipewire-control = pkgs.callPackage ./pipewire-control { };
  pipewire-output-tail = pkgs.callPackage ./pipewire-output-tail { };
  playerctl-tail = pkgs.callPackage ./playerctl-tail { };
  polywins = pkgs.callPackage ./polywins { };
  resize-aspect = pkgs.callPackage ./resize-aspect { };
  weather-bar = pkgs.callPackage ./weather-bar { };
}

