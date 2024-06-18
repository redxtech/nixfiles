{ pkgs, ... }:

let inherit (pkgs) callPackage;
in {
  clipboard = callPackage ./clipboard.nix { };
  copy-spotify-url = callPackage ./copy-spotify-url.nix { };
  ha = callPackage ./home-assistant.nix { };
  hdrop-btop = callPackage ./hdrop-btop.nix { };
  ps_mem = callPackage ./ps_mem.nix { };
  wttr = callPackage ./wttr.nix { };
}

