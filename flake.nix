{
  description = "My NixOS & home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";

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

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
    in {
      inherit lib;

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      overlays = import ./overlays { inherit inputs outputs; };

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells =
        forEachSystem (pkgs: import ./shell.nix { inherit pkgs inputs; });
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);

      nixosConfigurations = {
        # main desktop
        bastion = lib.nixosSystem {
          modules = [ ./hosts/bastion inputs.disko.nixosModules.disko ];
          specialArgs = { inherit inputs outputs; };
        };
        # laptop
        voyager = lib.nixosSystem {
          modules = [ ./hosts/voyager ];
          specialArgs = { inherit inputs outputs; };
        };
        # nas & media server
        quasar = lib.nixosSystem {
          modules = [ ./hosts/quasar ];
          specialArgs = { inherit inputs outputs; };
        };
        # # raspi - ??
        # gizmo = lib.nixosSystem {
        #   modules = [ ./hosts/gizmo ];
        #   specialArgs = { inherit inputs outputs; };
        # };
        # # nixiso
        # nixiso = lib.nixosSystem {
        #   modules = [ ./hosts/nixiso ];
        #   system = "x86_64-linux";
        #   specialArgs = { inherit inputs outputs; };
        # };
      };

      homeConfigurations = {
        "gabe@bastion" = lib.homeManagerConfiguration {
          modules = [ ./home/gabe/bastion.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "gabe@voyager" = lib.homeManagerConfiguration {
          modules = [ ./home/gabe/voyager.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "gabe@quasar" = lib.homeManagerConfiguration {
          modules = [ ./home/gabe/quasar.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "gabe@rock-hard" = lib.homeManagerConfiguration {
          modules = [ ./home/gabe/rock-hard.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "gabe@deck" = lib.homeManagerConfiguration {
          modules = [ ./home/gabe/deck.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        # "gabe@gizmo" = lib.homeManagerConfiguration {
        #   modules = [ ./home/gabe/gizmo.nix ];
        #   pkgs = pkgsFor.aarch64-linux;
        #   extraSpecialArgs = { inherit inputs outputs; };
        # };
      };

      defaultPackage = let
        cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgsFor.x86_64-linux;
      in cachix-deploy-lib.spec {
        agents = {
          voyager = cachix-deploy-lib.nixos {
            modules = [ ./hosts/voyager ];
            # pkgs = pkgsFor.x86_64-linux;
            specialArgs = { inherit inputs outputs; };
          };
          deck = cachix-deploy-lib.homeManager { } ({
            modules = [ ./home/gabe/deck.nix ];
            pkgs = pkgsFor.x86_64-linux;
            extraSpecialArgs = { inherit inputs outputs; };
          });
        };
      };
    };
}
