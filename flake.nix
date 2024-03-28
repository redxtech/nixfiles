{
  description = "My NixOS & home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-flake.url = "github:srid/nixos-flake";

    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
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
    xremap-flake.url = "github:xremap/nix-flake";
    # nur.url = "github:nix-community/NUR";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, flake-parts, hardware, ... }:
    let
      realHostNames = [ "bastion" "voyager" "quasar" ];

      extraSpecialArgs = {
        inherit inputs realHostNames;
        inherit (self) overlays;
      };

      modules = (import ./modules {
        inherit inputs extraSpecialArgs;
        inherit (self) nixosModules homeManagerModules lib overlays;
      });
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./modules/flake/deploy.nix ./modules/flake/shell.nix ];

      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = let lib = nixpkgs.lib // home-manager.lib;
      in {
        inherit lib;

        nixosModules = import ./modules/nixos;
        homeManagerModules = import ./modules/home-manager;

        overlays = import ./overlays { inherit inputs; };

        nixosConfigurations = let
          specialArgs = {
            inherit inputs realHostNames;
            inherit (self) overlays homeManagerModules;
          };
        in {
          # main desktop
          bastion = lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";
            modules = modules.nixos.bastion;
          };
          # laptop
          voyager = lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";
            modules = modules.nixos.voyager;
          };
          # nas & media server
          quasar = lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";
            modules = modules.nixos.quasar;
          };
          # # raspi - ??
          # gizmo = lib.nixosSystem {
          #   inherit specialArgs;
          #   modules = [ ./hosts/gizmo ] ++ commonModules;
          # };
          # # nixiso
          # nixiso = lib.nixosSystem {
          #   inherit specialArgs;
          #   modules = [ ./hosts/nixiso ] ++ commonModules;
          #   system = "x86_64-linux";
          # };
        };

        homeConfigurations = {
          "gabe@deck" = lib.homeManagerConfiguration {
            inherit extraSpecialArgs;
            modules = modules.home-manager.deck;
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
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
