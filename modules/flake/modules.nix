{ self, inputs, ... }:

let
  inherit (builtins) attrValues attrNames;
  inherit (inputs) nixpkgs;
in {
  flake = let
    allNixos = import ../nixos;
    allHomeManager = import ../home-manager;
    hardware = inputs.hardware.nixosModules;

    extraArgs = { pkgs, ... }:
      let
        pkgArgs = {
          inherit (self.nixCfg.nixpkgs) overlays;
          inherit (pkgs) system;
          config = { rocmSupport = true; } // self.nixCfg.nixpkgs.config;
        };
      in {
        _module.args = {
          inherit self inputs;
          inherit (pkgs) system;
          stable = import inputs.nixpkgs-stable pkgArgs;
          small = import inputs.nixpkgs-stable pkgArgs;
          hostnames = attrNames self.nixosConfigurations;
        };
      };

    homeCommon = [
      inputs.hyprland.homeManagerModules.default
      inputs.limbo.homeManagerModules.default
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      inputs.nur.hmModules.nur
      inputs.spicetify-nix.homeManagerModules.default
      inputs.tu.homeManagerModules.default

      extraArgs

      # shared nixpkgs config for home-manager
      { config = { inherit (self.nixCfg) nix; }; }
    ] ++ attrValues allHomeManager;

    nixosCommon = [
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.jovian.nixosModules.default
      inputs.nix-serve-ng.nixosModules.default
      inputs.solaar.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.xremap-flake.nixosModules.default

      ../../hosts/common

      extraArgs

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
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
        "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        inputs.disko.nixosModules.disko
        inputs.nur.nixosModules.nur

        ../../hosts/nixiso
      ] ++ nixosCommon;
    } // allNixos;

    homeManagerModules = {
      common = homeCommon;

      deck.imports = [ ../../home/gabe/deck.nix ] ++ homeCommon;
    } // allHomeManager;
  };
}
