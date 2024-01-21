{ config, pkgs, lib, ... }:

{
  imports = [ ../common ];

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
