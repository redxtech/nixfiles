{ config, pkgs, ... }:

{
  imports = [
    # ./kdeconnect.nix
    ./services.nix
    ./theme.nix
  ];

  home.packages = with pkgs; [ amdgpu_top glxinfo lshw pciutils spotify-tui ];

  xdg = {
    enable = true;

    userDirs = { videos = "$HOME/Videos"; };
  };
}
