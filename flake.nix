{
  description = "My NixOS & home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";
    nix-colors.url = "github:misterio77/nix-colors";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
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
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
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
        # nixiso
        nixiso = lib.nixosSystem {
          modules = [ ./hosts/nixiso ];
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
        };
        # # nas & media server
        # quasar = lib.nixosSystem {
        #   modules = [ ./hosts/quasar ];
        #   specialArgs = { inherit inputs outputs; };
        # };
        # # raspi - ??
        # gizmo = lib.nixosSystem {
        #   modules = [ ./hosts/gizmo ];
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
        # "gabe@quasar" = lib.homeManagerConfiguration {
        #   modules = [ ./home/gabe/quasar.nix ];
        #   pkgs = pkgsFor.x86_64-linux;
        #   extraSpecialArgs = { inherit inputs outputs; };
        # };
        # "gabe@gizmo" = lib.homeManagerConfiguration {
        #   modules = [ ./home/gabe/gizmo.nix ];
        #   pkgs = pkgsFor.aarch64-linux;
        #   extraSpecialArgs = { inherit inputs outputs; };
        # };
      };
    };
}
