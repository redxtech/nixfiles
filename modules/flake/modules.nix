{ self, inputs, lib, ... }:

let inherit (builtins) attrValues;
in {
  flake = let
    allNixos = import ../nixos;
    allHomeManager = import ../home-manager;

    homeCommon = [
      inputs.hyprland.homeManagerModules.default
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-flatpak.homeManagerModules.nix-flatpak

      { config = { inherit (self.nixCfg) nix; }; }
    ] ++ attrValues allHomeManager;

    nixosCommon = [
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.nh.nixosModules.default
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.solaar.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.xremap-flake.nixosModules.default

      ../../hosts/common

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
    } // allNixos;

    homeManagerModules = {
      common = homeCommon;

      deck.imports = [ ../../home/gabe/deck.nix ] ++ homeCommon;
    } // allNixos;
  };
}
