{ inputs, lib, ... }:

{
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
            allow-import-from-derivation = true;
            download-buffer-size = 1073741824;
          };

          # add each flake input as a registry
          # to make nix3 commands consistent with the flake
          registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
        };

        # nixpkgs.overlays = builtins.attrValues self.overlays;
        nixpkgs.config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    in
    {
      nixos = lib.mkMerge [
        {
          inherit (cfg) nix nixpkgs;

          systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

          # nix helper tool
          programs.nh = {
            enable = true;
            flake = "/home/gabe/Code/nixfiles";
            clean = {
              enable = true;
              extraArgs = "--keep-since 4d --keep 3";
            };
          };
        }
        {
          # enable hard-linking in nix store
          nix.optimise.automatic = true;
        }
      ];

      homeManager =
        { config, ... }:
        lib.mkMerge [
          {
            inherit (cfg) nix nixpkgs;

            # tell nh where to find the flake
            home.sessionVariables.NH_FLAKE = "${config.home.homeDirectory}/Code/nixfiles";
          }
          # merge omitted substituters to user nix config
          {
            nix.settings.substituters = [ "https://cache.nixos.org/" ];
            nix.settings.trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
          }
        ];
    };

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          input-fonts.acceptLicense = true;
        };
      };
    };
}
