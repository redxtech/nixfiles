{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  archiver = callPackage ./archiver.nix { };
  convert = callPackage ./convert-image.nix { };
  encoder = callPackage ./encoder.nix { };
  powermenu = callPackage ./powermenu.nix { };
  search-icons = callPackage ./search-icons.nix { };
}

