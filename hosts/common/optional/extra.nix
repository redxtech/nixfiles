{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
    let

      py-pkgs = ps: with ps; [ dbus-python pygobject3 requests ];
    in [

      fontforge
      librsvg
      nodejs
      # pyright
      (python3.withPackages py-pkgs)
      # rust-analyzer
      sqlite
      w3m
    ];
}
