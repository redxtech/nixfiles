{ pkgs, ... }: {
  fontProfiles = {
    enable = true;

    monospace = {
      family = "Dank Mono";
      package = pkgs.dank-mono;
    };

    regular = {
      family = "Noto Sans";
      package = pkgs.noto-fonts;
    };

    symbols = {
      family = "Nerd Fonts Symbols";
      package = pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; };
    };

    extraFonts = with pkgs; [
      cantarell-fonts
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
