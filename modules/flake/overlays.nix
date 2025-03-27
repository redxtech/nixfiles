{ self, inputs, ... }:

{
  flake = {
    overlays = {
      # adds my custom packages
      additions = final: prev: {
        # add neovim-nightly to the packages
        neovim-nightly = inputs.neovim-nightly.packages.${final.system}.default;

        plexPassRaw = prev.plexRaw.overrideAttrs (old: rec {
          version = "1.41.5.9522-a96edc606";
          name = "${old.pname}-${version}";

          src = prev.fetchurl {
            url =
              "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            hash = "sha256-3bGmsa2OLBt587YnZDNpSjWHdQ1ubwSNocLPW6A6kQU=";
          };
        });

        plexPass = prev.plex.override { plexRaw = final.plexPassRaw; };

        inherit (inputs.nix-autobahn.packages.${final.system}) nix-autobahn;

        # spicetify packages
        spicePkgs = inputs.spicetify-nix.legacyPackages.${final.system};
      };

      # Modifies existing packages
      modifications = final: prev: {
        fuzzel = prev.fuzzel.overrideAttrs (oldAttrs: {
          src = prev.fetchFromGitea {
            domain = "codeberg.org";
            owner = "dnkl";
            repo = "fuzzel";
            rev = "8e5ba7124faa59d644e43ea4f3a1702efe8270b5";
            hash = "sha256-Mops/SnnFPcKSzGmPUMUAL1tTklGYnaEiuZ1DBBB7/U=";
          };
        });

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
