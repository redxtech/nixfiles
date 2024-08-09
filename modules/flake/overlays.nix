{ self, inputs, ... }:

{
  flake = {
    overlays = {
      # adds my custom packages
      additions = final: prev: {
        # add neovim-nightly to the packages
        neovim-nightly = inputs.neovim-nightly.packages.${final.system}.default;

        plexPassRaw = prev.plexRaw.overrideAttrs (old: rec {
          version = "1.40.4.8679-424562606";
          name = "${old.pname}-${version}";

          src = if prev.stdenv.hostPlatform.system == "aarch64-linux" then
            prev.fetchurl {
              url =
                "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_arm64.deb";
              sha256 = "";
            }
          else
            prev.fetchurl {
              url =
                "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
              sha256 = "sha256-wVyA70xqZ9T8brPlzjov2j4C9W+RJYo99hO3VtNBVqw=";
            };
        });

        plexPass = prev.plex.override { plexRaw = final.plexPassRaw; };

        nix-autobahn =
          inputs.nix-autobahn.packages.${final.system}.nix-autobahn;

        # spicetify packages
        spicePkgs = inputs.spicetify-nix.legacyPackages.${final.system};
      };

      # Modifies existing packages
      modifications = final: prev: {
        # rofi = prev.rofi.override { plugins = [ prev.rofi-emoji ]; };
        rofi = prev.rofi-wayland.override { plugins = [ prev.rofi-emoji ]; };

        # use solaar from the flake
        solaar = inputs.solaar.packages.${final.system}.default;

        # include plugins with thunar
        thunar = prev.xfce.thunar.override {
          thunarPlugins =
            [ prev.xfce.thunar-archive-plugin prev.xfce.thunar-volman ];
        };

        vivaldi = prev.vivaldi.override {
          commandLineArgs = "--force-dark-mode";
          proprietaryCodecs = true;
          # enableWidevine = true; # TODO: vivaldi crashes when this is enabled, need to fix
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
      flakehub = inputs.fh.overlays.default;
      # hyprland = inputs.hyprland.overlays.default;
      # hyprland-contrib = inputs.hyprland-contrib.overlays.default;
      # hyprland-plugins = inputs.hyprland-plugins.overlays.default;
      # hyprland-xdph = inputs.hyprland-xdph.overlays.default;
      # hyprlock = inputs.hyprlock.overlays.default;
      limbo = inputs.limbo.overlays.default;
      swww = inputs.swww.overlays.default;
      # nix-neovim-plugins = inputs.nix-neovim-plugins.overlays.default;
      # nur = inputs.nur.overlay;
    };
  };
}
