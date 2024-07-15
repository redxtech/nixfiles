{ self, inputs, lib, ... }:

let inherit (builtins) attrValues;
in {
  flake = let
    allNixos = import ../nixos;
    allHomeManager = import ../home-manager;

    stableNixpkgs = ({ pkgs, ... }: {
      _module.args.stable = import inputs.nixpkgs-stable {
        inherit (self.nixCfg.nixpkgs) overlays;
        system = pkgs.system;
        config = { rocmSupport = true; } // self.nixCfg.nixpkgs.config;
      };
    });

    homeCommon = [
      inputs.hyprland.homeManagerModules.default
      inputs.limbo.homeManagerModules.default
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      inputs.spicetify-nix.homeManagerModules.default

      # global stable nixpkgs module for all systems
      stableNixpkgs

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

      bastion.imports = [
        ../../hosts/bastion

        inputs.hardware.nixosModules.common-cpu-amd
        inputs.hardware.nixosModules.common-gpu-amd
        inputs.hardware.nixosModules.common-pc-ssd

        inputs.disko.nixosModules.disko
      ] ++ nixosCommon;

      voyager.imports = [
        ../../hosts/voyager

        inputs.hardware.nixosModules.dell-xps-15-7590-nvidia
        inputs.hardware.nixosModules.common-cpu-intel-cpu-only
        inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
        inputs.hardware.nixosModules.common-pc-ssd
      ] ++ nixosCommon;

      quasar.imports = [
        ../../hosts/quasar

        inputs.hardware.nixosModules.common-cpu-intel-cpu-only
        inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
        inputs.hardware.nixosModules.common-pc-ssd
      ] ++ nixosCommon;

      deck.imports = [
        ../../hosts/deck

        inputs.hardware.nixosModules.common-cpu-amd
        inputs.hardware.nixosModules.common-gpu-amd
        inputs.hardware.nixosModules.common-pc-ssd
      ] ++ nixosCommon;
    } // allNixos;

    homeManagerModules = {
      common = homeCommon;

      deck.imports = [ ../../home/gabe/deck.nix ] ++ homeCommon;
    } // allHomeManager;
  };
}
