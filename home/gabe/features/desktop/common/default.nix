{ config, pkgs, ... }:

{
  imports = [
    ./desktop-apps.nix
    # ./font.nix
    # ./kdeconnect.nix
    ./theme.nix
  ];

  home.packages = with pkgs; [ glxinfo spotify-tui ];

  xdg = {
    enable = true;

    userDirs = { videos = "$HOME/Videos"; };
  };
}
