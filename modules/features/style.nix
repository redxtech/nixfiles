{ inputs, ... }:

{
  den.aspects.style =
    let
      extraFonts = pkgs: inputCustom: [
        inputCustom
        pkgs.aporetic-bin
        pkgs.cantarell-fonts
        pkgs.inter
        pkgs.iosevka
        pkgs.xkcd-font
        pkgs.nerd-fonts.symbols-only
      ];
    in
    {
      nixos =
        { pkgs, self', ... }:
        {
          imports = [ inputs.stylix.nixosModules.stylix ];

          stylix = {
            enable = true;
            base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
            polarity = "dark";

            cursor = {
              name = "Vimix-cursors";
              package = pkgs.vimix-cursors;
              size = 32;
            };

            fonts = {
              serif = {
                name = "Noto Serif";
                package = pkgs.noto-fonts;
              };

              sansSerif = {
                name = "Noto Sans";
                package = pkgs.noto-fonts;
              };

              monospace = {
                name = "Input Mono Condensed";
                package = self'.packages.input-custom;
              };

              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
            };

            icons = {
              enable = true;
              package = pkgs.papirus-icon-theme;
              dark = "Papirus-Dark";
              light = "Papirus-Light";
            };

            opacity.terminal = 0.9;
          };

          fonts.fontDir.enable = true;
          environment.systemPackages = extraFonts pkgs self'.packages.input-custom;
        };

      homeManager =
        { pkgs, self', ... }:
        {
          fonts.fontconfig.antialiasing = true;
          home.pointerCursor.enable = true;
          home.packages = extraFonts pkgs self'.packages.input-custom;
        };
    };

  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
