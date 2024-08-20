{ self, inputs, ... }:

let inherit (builtins) attrValues;
in {
  flake = let
    allNixos = import ../nixos;
    allHomeManager = import ../home-manager;
    hardware = inputs.hardware.nixosModules;

    hostnames = {
      _module.args.hostnames = builtins.attrNames self.nixosConfigurations;
      _module.args.inputs = inputs;
    };

    stableNixpkgs = { pkgs, ... }: {
      _module.args.stable = import inputs.nixpkgs-stable {
        inherit (self.nixCfg.nixpkgs) overlays;
        inherit (pkgs) system;
        config = { rocmSupport = true; } // self.nixCfg.nixpkgs.config;
      };
    };

    homeCommon = [
      inputs.hyprland.homeManagerModules.default
      inputs.limbo.homeManagerModules.default
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      inputs.spicetify-nix.homeManagerModules.default
      inputs.tu.homeManagerModules.default
      # global stable nixpkgs module for all systems
      stableNixpkgs
      hostnames

      # shared nixpkgs config for home-manager
      { config = { inherit (self.nixCfg) nix; }; }
    ] ++ attrValues allHomeManager;

    nixosCommon = [
      inputs.attic.nixosModules.atticd
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.jovian.nixosModules.default
      inputs.solaar.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.xremap-flake.nixosModules.default

      ../../hosts/common

      # global stable nixpkgs module for all systems
      stableNixpkgs
      hostnames

      # shared nixpkgs config for home-manager
      {
        config = {
          inherit (self.nixCfg) nix nixpkgs;

          home-manager = {
            sharedModules = homeCommon;
            useGlobalPkgs = true;
          };
        };
      }
    ] ++ attrValues allNixos;
  in {
    nixosModules = {
      common = nixosCommon;

      bastion.imports = with hardware;
        [
          ../../hosts/bastion

          common-cpu-amd
          common-gpu-amd
          common-pc-ssd

          inputs.disko.nixosModules.disko
        ] ++ nixosCommon;

      voyager.imports = with hardware;
        [
          ../../hosts/voyager

          framework-16-7040-amd

          inputs.disko.nixosModules.disko
        ] ++ nixosCommon;

      quasar.imports = with hardware;
        [
          ../../hosts/quasar

          common-cpu-intel-cpu-only
          common-gpu-nvidia-nonprime
          common-pc-ssd
        ] ++ nixosCommon;

      deck.imports = with hardware;
        [
          ../../hosts/deck

          common-cpu-amd
          common-gpu-amd
          common-pc-ssd
        ] ++ nixosCommon;

      nixiso.imports = [
        ../../hosts/nixiso

        inputs.disko.nixosModules.disko
      ];
    } // allNixos;

    homeManagerModules = {
      common = homeCommon;

      deck.imports = [ ../../home/gabe/deck.nix ] ++ homeCommon;
    } // allHomeManager;
  };
}
