{ self, inputs, ... }:

{
  flake = {
    overlays = {
      # adds my custom packages
      additions = final: prev: {
        # add neovim-nightly to the packages
        neovim-nightly = inputs.neovim-nightly.packages.${final.system}.default;

        plexPassRaw = prev.plexRaw.overrideAttrs (old: rec {
          version = "1.42.2.10156-f737b826c";
          name = "${old.pname}-${version}";

          src = prev.fetchurl {
            url =
              "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            hash = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
          };
        });

        plexPass = prev.plex.override { plexRaw = final.plexPassRaw; };

        inherit (inputs.nix-autobahn.packages.${final.system}) nix-autobahn;

        # spicetify packages
        spicePkgs = inputs.spicetify-nix.legacyPackages.${final.system};
      };

      # Modifies existing packages
      modifications = final: prev: {
        fuzzel = prev.fuzzel.overrideAttrs (oldAttrs: rec {
          version = "1.13.1";
          src = prev.fetchFromGitea {
            domain = "codeberg.org";
            owner = "dnkl";
            repo = "fuzzel";
            tag = version;
            hash = "sha256-JW6MvLXax7taJfBjJjRkEKCczzO4AYsQ47akJK2pkh0=";
          };
        });

        rofi = prev.rofi.override { plugins = [ prev.rofi-emoji ]; };

        # use solaar from the flake
        solaar = inputs.solaar.packages.${final.system}.default;

        # include plugins with thunar
        thunar = prev.xfce.thunar.override {
          thunarPlugins =
            [ prev.xfce.thunar-archive-plugin prev.xfce.thunar-volman ];
        };

        zinit = prev.zinit.overrideAttrs (oldAttrs: {
          installPhase = ''
            outdir="$out/share/$pname"
            cd "$src"
            ls -al doc

            # Zplugin's source files
            install -dm0755 "$outdir"
            # Installing backward compatibility layer
            install -m0644 zinit{,-side,-install,-autoload}.zsh "$outdir"
            install -m0755 share/git-process-output.zsh "$outdir"
            mkdir -p "$outdir/doc"
            install doc/zinit.1 "$outdir/doc/zinit.1"

            # Zplugin autocompletion
            installShellCompletion --zsh _zinit
          '';
        });
      };

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
