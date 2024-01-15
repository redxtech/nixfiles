{ pkgs, inputs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;

    packages = [
      "com.getpostman.Postman"
      "com.obsproject.Studio"
      "dev.vencord.Vesktop"
    ];
  };

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [ xdg-desktop-portal ];
    xdgOpenUsePortal = false;

    config = { common.default = "*"; };
  };
}

