{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      dank-mono
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "Hack"
          "Inconsolata"
          "JetBrainsMono"
          "NerdFontsSymbolsOnly"
          "Noto"
        ];
      })
      jetbrains-mono
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      noto-fonts-extra
    ];
  };
}
