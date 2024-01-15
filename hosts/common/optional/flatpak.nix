{ pkgs, inputs, ... }:

{
  services.flatpak = {
    enable = true;

    packages = [
      # "com.obsproject.Studio"
      # "dev.vencord.Vesktop"
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal ];
    config = { common.default = "*"; };
  };
}
