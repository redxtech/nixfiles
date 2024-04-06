{ pkgs, lib, config, ... }:

{
  imports = [
    ./global

    ./features/desktop/gnome
  ];

  cli.enable = true;

  home.packages = with pkgs; [ moonlight-qt ];
}
