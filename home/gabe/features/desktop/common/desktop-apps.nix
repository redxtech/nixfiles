{ config, pkgs, inputs, system, ... }:

{
  imports = [ ./kitty.nix ./firefox ./flatpak.nix ./mpv.nix ./rio.nix ];

  home.packages = with pkgs; [
    arandr
    # audacity
    beekeeper-studio-ultimate
    betterdiscordctl
    deluge
    discord
    libreoffice
    multiviewer-for-f1
    neovide
    pavucontrol
    playerctl
    plexamp
    qdirstat
    slack
    spotifywm
    xdragon
    xfce.exo
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    vivaldi
    vlc
  ];

  programs = {
    feh.enable = true;
    zathura.enable = true;
  };

  services.playerctld = { enable = true; };

  xdg.configFile."variety/set_wp.sh" = {
    text = let
      set_wp = pkgs.writeShellApplication {
        name = "set_wp";
        runtimeInputs = with pkgs; [ betterlockscreen coreutils feh glib ];

        text = builtins.readFile ./set_wp.sh;
      };
    in ''
      ${set_wp}/bin/set_wp "$@"
    '';
    executable = true;
  };
}

