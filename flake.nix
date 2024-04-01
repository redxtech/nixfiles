{
  description = "My NixOS & home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-flake.url = "github:srid/nixos-flake";

    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    cachix-deploy-flake.inputs.nixpkgs.follows = "nixpkgs";
    cachix-deploy-flake.inputs.home-manager.follows = "home-manager";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sddm-catppuccin.url = "github:khaneliman/sddm-catppuccin";
    sddm-catppuccin.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:viperML/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    solaar.url = "github:Svenum/Solaar-Flake/latest";
    solaar.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";

    deploy-rs.url = "github:serokell/deploy-rs";
    devenv.url = "github:cachix/devenv";
    fh.url = "github:DeterminateSystems/fh";
    hardware.url = "github:nixos/nixos-hardware";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-autobahn.url = "github:lassulus/nix-autobahn";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    rust-overlay.url = "github:oxalica/rust-overlay";
    xremap-flake.url = "github:redxtech/xremap-flake";
    # nur.url = "github:nix-community/NUR";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, flake-parts, hardware, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/flake/deploy.nix
        ./modules/flake/nix.nix
        ./modules/flake/modules.nix
        ./modules/flake/overlays.nix
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
        };

        homeConfigurations = {
          "gabe@deck" = home-manager.lib.homeManagerConfiguration {
            modules = [ self.homeManagerModules.deck ];
            pkgs = import nixpkgs {
              inherit (self.nixCfg.nixpkgs) config overlays;
              system = "x86_64-linux";
            };
          };
        };
      };

      # per-system attributes can be defined here. the self' and inputs'
      # module parameters provide easy access to attributes of the same
      # system.
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = (import ./pkgs { inherit pkgs; });

        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
