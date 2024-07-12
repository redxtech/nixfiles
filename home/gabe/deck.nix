{ config, pkgs, ... }:

{
  imports = [
    ./global

    ./features/desktop/gnome
  ];

  cli.enable = true;

  # enable some things
  services.syncthing.enable = true;

  # disable some things
  desktop.spicetify.enable = false;
  programs.neovim.neo-lsp.enable = false;

  home.packages = with pkgs; [ moonlight-qt ];
}
