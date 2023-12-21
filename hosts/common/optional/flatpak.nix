{ pkgs, inputs, ... }:

{
  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal ];
    config = { common.default = "*"; };
  };
}
