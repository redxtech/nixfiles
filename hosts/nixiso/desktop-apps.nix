{ config, pkgs, ... }:

{
  programs = {
    partition-manager.enable = true;

    thunar = {
      enable = true;

      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
    };

    xfconf.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # gui apps
    firefox-devedition-bin
    gnome.gnome-software
    kitty
    mpv
    spotifywm
  ];
}
