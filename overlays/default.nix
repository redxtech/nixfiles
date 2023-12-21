{ outputs, inputs }:
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
    };

  # Modifies existing packages
  modifications = final: prev: {
    vimPlugins = prev.vimPlugins // {
      # vim-numbertoggle = addPatches prev.vimPlugins.vim-numbertoggle
      #   [ ./vim-numbertoggle-command-mode.patch ];
    };

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

    vivaldi = prev.vivaldi.override {
      commandLineArgs = "--force-dark-mode";
      proprietaryCodecs = true;
      # enableWidevine = true; # TODO: vivaldi crashes when this is enabled, need to fix
    };

  };
}
