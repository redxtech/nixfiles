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

    devenv.url = "github:cachix/devenv";
    fh.url = "github:DeterminateSystems/fh";
    hardware.url = "github:nixos/nixos-hardware";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-autobahn.url = "github:lassulus/nix-autobahn";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    rust-overlay.url = "github:oxalica/rust-overlay";
    xremap-flake.url = "github:xremap/nix-flake";
    # nur.url = "github:nix-community/NUR";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # inputs.nixos-flake.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = let
        lib = nixpkgs.lib // home-manager.lib;
        realHostNames = [
          "bastion"
          "voyager"
          "quasar"
          # "gizmo"
        ];
      in rec {
        inherit lib;

        nixosModules = import ./modules/nixos;
        homeManagerModules = import ./modules/home-manager;

        overlays = import ./overlays { inherit inputs; };

        nixosConfigurations = let
          commonModules = [ ./hosts/common ]
            ++ (builtins.attrValues nixosModules);
          specialArgs = {
            inherit inputs overlays realHostNames homeManagerModules;
          };
        in {
          # main desktop
          bastion = lib.nixosSystem {
            inherit specialArgs;
            modules = [ ./hosts/bastion ] ++ commonModules;
          };
          # laptop
          voyager = lib.nixosSystem {
            inherit specialArgs;
            modules = [ ./hosts/voyager ] ++ commonModules;
          };
          # nas & media server
          quasar = lib.nixosSystem {
            inherit specialArgs;
            modules = [ ./hosts/quasar ] ++ commonModules;
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

        homeConfigurations = let
          commonModules = (builtins.attrValues homeManagerModules);
          extraSpecialArgs = { inherit inputs overlays realHostNames; };
        in {
          "gabe@deck" = lib.homeManagerConfiguration {
            inherit extraSpecialArgs;
            modules = [ ./home/gabe/deck.nix ] ++ commonModules;
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
        packages = {
          # default = let cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
          # in cachix-deploy-lib.spec { agents = { }; };
        } // (import ./pkgs { inherit pkgs; });

        devShells = import ./shell.nix {
          inherit pkgs;
          inputs = inputs';
        };

        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
