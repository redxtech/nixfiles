{
  inputs,
  self,
  lib,
  ...
}:

{
  # TODO: see how to get this working
  # imports = [ inputs.flake-file.flakeModules.allfollow ];

  den.aspects.nix-config =
    let
      cfg = {
        nix = {
          settings = {
            trusted-users = [
              "root"
              "gabe"
              "@wheel"
            ];
            experimental-features = "nix-command flakes";
            substituters = [
              "https://nix-community.cachix.org"
              "https://gabedunn.cachix.org"
            ];
            trusted-public-keys = [
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "gabedunn.cachix.org-1:wLWTKadNjpr2Op3rBnDZMUmUEPPIoKG87oY4PmBP8qU="
            ];
            auto-optimise-store = lib.mkDefault true;
            warn-dirty = false;
            download-buffer-size = 1073741824;
          };

          # add each flake input as a registry
          # to make nix3 commands consistent with the flake
          registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
        };

        nixpkgs.config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    in
    {
      nixos = {
        inherit (cfg) nix nixpkgs;

      };

      homeManager =
        { config, ... }:
        {
          inherit (cfg) nix nixpkgs;

          # nix helper tool
          programs.nh = {
            enable = true;
            flake = "${config.home.homeDirectory}/Code/nixfiles";
            clean = {
              enable = true;
              extraArgs = "--keep-since 4d --keep 3";
            };
          };

          # tell nh where to find the flake
          home.sessionVariables.NH_FLAKE = "${config.home.homeDirectory}/Code/nixfiles";
        };
    };
}
