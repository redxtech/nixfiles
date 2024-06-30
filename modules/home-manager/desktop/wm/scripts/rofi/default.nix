{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  convert = callPackage ./convert-image.nix { };
}

