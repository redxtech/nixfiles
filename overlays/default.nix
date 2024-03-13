{ inputs }:

let
  addPatches = pkg: patches:
    pkg.overrideAttrs
    (oldAttrs: { patches = (oldAttrs.patches or [ ]) ++ patches; });
in {
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (_: flake:
      let
        legacyPackages = ((flake.legacyPackages or { }).${final.system} or { });
        packages = ((flake.packages or { }).${final.system} or { });
      in if legacyPackages != { } then legacyPackages else packages) inputs;
  };

  # Adds my custom packages
  additions = final: prev:
    import ../pkgs { pkgs = final; } // {
      # formats = prev.formats // import ../pkgs/formats { pkgs = final; };
      # vimPlugins = prev.vimPlugins // final.callPackage ../pkgs/vim-plugins { };

      plexPassRaw = prev.plexRaw.overrideAttrs (old: rec {
        version = "1.32.8.7639-fb6452ebf";
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
            sha256 = "sha256-jdGVAdvm7kjxTP3CQ5w6dKZbfCRwSy9TrtxRHaV0/cs=";
          };
      });

      plexPass = prev.plex.override { plexRaw = final.plexPassRaw; };

      nix-autobahn = inputs.nix-autobahn.packages.${final.system}.nix-autobahn;
    };

  # Modifies existing packages
  modifications = final: prev: {
    vimPlugins = prev.vimPlugins // {
      # vim-numbertoggle = addPatches prev.vimPlugins.vim-numbertoggle
      #   [ ./vim-numbertoggle-command-mode.patch ];
    };

    # update the version of the package
    adguardhome = prev.adguardhome.overrideAttrs (oldAttrs: rec {
      version = "0.107.43";
      src = final.fetchurl {
        url =
          "https://github.com/AdguardTeam/AdGuardHome/releases/download/v${version}/AdGuardHome_linux_amd64.tar.gz";
        sha256 = "sha256-Ck4+7HTKVuLykwVEX1rAWWJE+6bT/oIWQ1LTB7Qkls8=";
      };
    });

    # https://github.com/NixOS/nix/issues/5567#issuecomment-1193259926
    # nix = addPatches prev.nix [ ./nix-make-installables-expr-context.patch ];
    pfetch = prev.pfetch.overrideAttrs (oldAttrs: {
      version = "unstable-2021-12-10";
      src = final.fetchFromGitHub {
        owner = "dylanaraps";
        repo = "pfetch";
        rev = "a906ff89680c78cec9785f3ff49ca8b272a0f96b";
        sha256 = "sha256-9n5w93PnSxF53V12iRqLyj0hCrJ3jRibkw8VK3tFDvo=";
      };
      # Add term option, rename de to desktop, add scheme option
      patches = (oldAttrs.patches or [ ]) ++ [ ./pfetch.patch ];
    });

    rofi = prev.rofi.override { plugins = [ prev.rofi-emoji ]; };
    # rofi = prev.rofi-wayland.override { plugins = [ prev.rofi-emoji ]; };

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

  flakehub = inputs.fh.overlays.default;
  neovim-nightly = inputs.neovim-nightly-overlay.overlay;
  rust-overlay = inputs.rust-overlay.overlays.default;
  # nur = inputs.nur.overlay;
  # inputs.nix-minecraft.overlay
}
