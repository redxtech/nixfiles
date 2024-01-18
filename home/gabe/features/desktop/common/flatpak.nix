{ pkgs, config, inputs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;

    packages = [ "com.getpostman.Postman" "com.obsproject.Studio" ];
  };

  xdg.dataFile."fonts".source =
    config.lib.file.mkOutOfStoreSymlink /run/current-system/sw/share/X11/fonts;

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [ xdg-desktop-portal ];
    xdgOpenUsePortal = false;

    config = { common.default = "*"; };
  };
}

