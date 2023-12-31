{ config, pkgs, ... }:

{
  imports = [
    ./desktop-apps.nix
    # ./kdeconnect.nix
    ./services.nix
    ./theme.nix
  ];

  home.packages = with pkgs; [ glxinfo spotify-tui ];

  xdg = {
    enable = true;

    userDirs = { videos = "$HOME/Videos"; };
  };
}
