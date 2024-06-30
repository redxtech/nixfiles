{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  archiver = callPackage ./archiver.nix { };
  convert = callPackage ./convert-image.nix { };
}

