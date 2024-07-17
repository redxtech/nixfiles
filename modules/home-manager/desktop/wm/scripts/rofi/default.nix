{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  archiver = callPackage ./archiver.nix { };
  convert = callPackage ./convert-image.nix { };
  encoder = callPackage ./encoder.nix { };
  nerd-icons = callPackage ./nerd-icons { };
  powermenu = callPackage ./powermenu.nix { };
  search-icons = callPackage ./search-icons.nix { };
  youtube = callPackage ./youtube.nix { };
}

