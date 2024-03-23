{ inputs, nixosModules, homeManagerModules, ... }:

rec {
  nixos = {
    common = [ ../hosts/common ] ++ (builtins.attrValues nixosModules);

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

  home-manager = rec {
    common = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-colors.homeManagerModules.default
    ] ++ (builtins.attrValues homeManagerModules);

    deck = [ ../home/gabe/deck.nix { imports = [ home-manager.common ]; } ];
  };
}
