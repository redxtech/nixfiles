{ config, pkgs, ... }:

{
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Dank Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    fontDir.enable = true;

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

  # TODO: look at kmscon for better console fonts
  # console = {
  #   font = "";
  #   packages = [ ];
  # };
}
