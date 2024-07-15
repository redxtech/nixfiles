{ pkgs, lib, config, ... }:

{
  imports = [
    ./global

    ./features/desktop/gnome
  ];

  cli.enable = true;

  desktop.monitors = [ ];

  home.packages = with pkgs; [ moonlight-qt ];
}
