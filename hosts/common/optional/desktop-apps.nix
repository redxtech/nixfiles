{ config, pkgs, ... }:

{
  programs = {
    dconf.enable = true;
    gnupg.agent.enable = true;
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
    flameshot
    gnome.gnome-software
    gnome.gpaste
    kitty
    mpv
    obsidian
    spotifywm
    vivaldi
    vscodium

    # thunar tools
    webp-pixbuf-loader
    poppler
    ffmpegthumbnailer
    freetype
    libgsf
    gnome-epub-thumbnailer
  ];
}
