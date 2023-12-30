{ pkgs, lib, ... }:

{
  rofi-clipboard = pkgs.callPackage ./clipboard { };
  rofi-nerd-icons = pkgs.callPackage ./nerd-icons { };
  rofi-powermenu = pkgs.callPackage ./powermenu { };
  rofi-screenshot = pkgs.callPackage ./screenshot { };
  rofi-web = pkgs.callPackage ./web { };
  rofi-youtube = pkgs.callPackage ./youtube { };
}

