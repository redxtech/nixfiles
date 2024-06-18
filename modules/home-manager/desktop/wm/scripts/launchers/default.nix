{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  app-launcher = callPackage ./app-launcher.nix { };
  powermenu = callPackage ./powermenu.nix { };
}

