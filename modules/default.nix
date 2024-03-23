{ inputs, nixosModules, homeManagerModules, ... }:

let
  homeCommon = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ] ++ (builtins.attrValues homeManagerModules);
in rec {
  nixos = {
    common = [
      ../hosts/common

      inputs.home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.solaar.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.xremap-flake.nixosModules.default

      { config.home-manager.sharedModules = homeCommon; }

    ] ++ (builtins.attrValues nixosModules);

    bastion = [
      ../hosts/bastion

      inputs.hardware.nixosModules.common-cpu-amd
      inputs.hardware.nixosModules.common-gpu-amd
      inputs.hardware.nixosModules.common-pc-ssd

      inputs.disko.nixosModules.disko
    ] ++ nixos.common;

    voyager = [
      ../hosts/voyager

      inputs.hardware.nixosModules.dell-xps-15-7590-nvidia
      inputs.hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
      inputs.hardware.nixosModules.common-pc-ssd
    ] ++ nixos.common;

    quasar = [
      ../hosts/quasar

      inputs.hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
      inputs.hardware.nixosModules.common-pc-ssd
    ] ++ nixos.common;
  };

  home-manager = {
    deck = [ ../home/gabe/deck.nix ({ imports = homeCommon; }) ];
  };
}
