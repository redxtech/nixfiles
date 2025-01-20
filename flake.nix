{
  description = "My NixOS & home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-small.url = "github:nixos/nixpkgs/nixos-unstable-small";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-flake.url = "github:srid/nixos-flake";

    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    cachix-deploy-flake.inputs.nixpkgs.follows = "nixpkgs";
    cachix-deploy-flake.inputs.home-manager.follows = "home-manager";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    firefox.url = "github:nix-community/flake-firefox-nightly";
    firefox.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    solaar.url = "github:redxtech/Solaar-Flake/main";
    solaar.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    tu.url = "github:redxtech/tu";

    deploy-rs.url = "github:serokell/deploy-rs";
    devenv.url = "github:cachix/devenv";
    fh.url = "github:DeterminateSystems/fh";
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";
    hardware.url = "github:nixos/nixos-hardware";
    hci-effects.url = "github:hercules-ci/hercules-ci-effects";
    limbo.url = "github:co-conspirators/limbo";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    nix-autobahn.url = "github:lassulus/nix-autobahn";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-neovim-plugins.url = "github:NixNeovim/NixNeovimPlugins";
    nix-serve-ng.url = "github:aristanetworks/nix-serve-ng";
    quickgui.url =
      "https://flakehub.com/f/quickemu-project/quickgui/1.2.10.tar.gz";
    swww.url = "github:LGFae/swww";
    xremap-flake.url = "github:xremap/nix-flake";
    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, flake-parts, hardware
    , quickgui, ... }:
    let
      mkLib = nixpkgs: nixpkgs.lib.extend (final: prev: (import ./lib final));
      customLib = mkLib nixpkgs;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/flake/ci.nix
        ./modules/flake/deploy.nix
        ./modules/flake/nix.nix
        ./modules/flake/nixiso.nix
        ./modules/flake/modules.nix
        ./modules/flake/overlays.nix
        ./modules/flake/packages.nix
        ./modules/flake/schemas.nix
        ./modules/flake/shell.nix
      ];

      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        nixosConfigurations = {
          # main desktop
          bastion = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.bastion ];
          };
          # laptop
          voyager = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.voyager ];
          };
          # nas & media server
          quasar = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.quasar ];
          };
          # iso for usb stick
          nixiso = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.nixiso ];
          };
        };

        lib = customLib;
      };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
