{ inputs, self, ... }:

{
  den.aspects.style = {
    nixos =
      { pkgs, ... }:
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
              name = "Aporetic Sans Mono";
              package = pkgs.aporetic-bin;
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

        # extra fonts
        environment.systemPackages = with pkgs; [
          cantarell-fonts
          inter
          xkcd-font
          nerd-fonts.symbols-only
        ];
      };

    # silence the warning
    # TODO: see if it works with setting this to config.gtk.theme
    homeManager =
      { pkgs, ... }:
      {
        gtk.gtk4.theme = null;

        fonts.fontconfig.antialiasing = true;
        home.packages = with pkgs; [
          cantarell-fonts
          inter
          xkcd-font
          nerd-fonts.symbols-only
        ];
      };
  };

  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
