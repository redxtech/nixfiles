{ self, inputs, ... }:

{
  flake = {
    overlays = {
      # adds my custom packages
      additions = final: prev: {
        # add neovim-nightly to the packages
        neovim-nightly = inputs.neovim-nightly.packages.${final.stdenv.hostPlatform.system}.default;

        plexPassRaw = prev.plexRaw.overrideAttrs (old: rec {
          version = "1.42.2.10156-f737b826c";
          name = "${old.pname}-${version}";

          src = prev.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            hash = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
          };
        });

        plexPass = prev.plex.override { plexRaw = final.plexPassRaw; };

        inherit (inputs.nix-autobahn.packages.${final.stdenv.hostPlatform.system})
          nix-autobahn
          ;

        # spicetify packages
        spicePkgs = inputs.spicetify-nix.legacyPackages.${final.stdenv.hostPlatform.system};
      };

      # Modifies existing packages
      modifications = final: prev: {
        rofi = prev.rofi.override { plugins = [ prev.rofi-emoji ]; };

        # use solaar from the flake
        solaar = inputs.solaar.packages.${final.stdenv.hostPlatform.system}.default;

        # include plugins with thunar
        thunar = prev.thunar.override { thunarPlugins = [ prev.thunar-volman ]; };
      };

      citron = inputs.citron.overlays.default;
      fenix = inputs.fenix.overlays.default;
      # hyprland = inputs.hyprland.overlays.default;
      # hyprland-contrib = inputs.hyprland-contrib.overlays.default;
      # hyprland-plugins = inputs.hyprland-plugins.overlays.default;
      # hyprland-xdph = inputs.hyprland-xdph.overlays.default;
      # hyprlock = inputs.hyprlock.overlays.default;
      swww = inputs.swww.overlays.default;
      # nix-neovim-plugins = inputs.nix-neovim-plugins.overlays.default;
      # nur = inputs.nur.overlay;
    };
  };
}
