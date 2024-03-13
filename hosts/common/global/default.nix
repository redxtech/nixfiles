# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, pkgs, ... }: {
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ]
    ++ (builtins.attrValues outputs.nixosModules);
}
