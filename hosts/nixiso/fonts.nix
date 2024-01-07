{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      (nerdfonts.override {
        fonts = [ "FiraCode" "NerdFontsSymbolsOnly" "Noto" ];
      })
      noto-fonts
      noto-fonts-emoji
    ];
  };
}
