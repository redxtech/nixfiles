# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak

    ./cli.nix
    ./sops.nix
  ] ++ (builtins.attrValues outputs.nixosModules);
}
