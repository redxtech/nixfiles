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
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
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

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells =
        forEachSystem (pkgs: import ./shell.nix { inherit pkgs inputs; });
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);

      nixosConfigurations = let
        commonModules = [ ./hosts/common ]
          ++ (builtins.attrValues nixosModules);
        specialArgs = {
          inherit inputs overlays packages realHostNames homeManagerModules;
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
        extraSpecialArgs = { inherit inputs overlays packages realHostNames; };
      in {
        "gabe@bastion" = lib.homeManagerConfiguration {
          inherit extraSpecialArgs;
          modules = [ ./home/gabe/bastion.nix ] ++ commonModules;
          pkgs = pkgsFor.x86_64-linux;
        };
        "gabe@voyager" = lib.homeManagerConfiguration {
          inherit extraSpecialArgs;
          modules = [ ./home/gabe/voyager.nix ] ++ commonModules;
          pkgs = pkgsFor.x86_64-linux;
        };
        "gabe@quasar" = lib.homeManagerConfiguration {
          inherit extraSpecialArgs;
          modules = [ ./home/gabe/quasar.nix ] ++ commonModules;
          pkgs = pkgsFor.x86_64-linux;
        };
        "gabe@deck" = lib.homeManagerConfiguration {
          inherit extraSpecialArgs;
          modules = [ ./home/gabe/deck.nix ] ++ commonModules;
          pkgs = pkgsFor.x86_64-linux;
        };
        # "gabe@gizmo" = lib.homeManagerConfiguration {
        #   inherit extraSpecialArgs;
        #   modules = [ ./home/gabe/gizmo.nix ];
        #   pkgs = pkgsFor.aarch64-linux;
        # };
      };
    };
}
