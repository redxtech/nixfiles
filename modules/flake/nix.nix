{ self, inputs, lib, ... }:

{
  flake = {
    nixCfg = {
      nix = {
        settings = {
          trusted-users = [ "root" "@wheel" "gabe" ];
          experimental-features = [ "nix-command" "flakes" "repl-flake" ];
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://devenv.cachix.org"
            "https://gabedunn.cachix.org"
            "https://hyprland.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "gabedunn.cachix.org-1:wLWTKadNjpr2Op3rBnDZMUmUEPPIoKG87oY4PmBP8qU="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          ];
          auto-optimise-store = lib.mkDefault true;
          warn-dirty = false;
          system-features = [ "kvm" "big-parallel" "nixos-test" ];
        };
        gc = {
          automatic = true;
          options = "--delete-older-than 5d";
        };

        # add each flake input as a registry
        # to make nix3 commands consistent with the flake
        registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      };

      nixpkgs = {
        overlays = builtins.attrValues self.overlays;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-25.9.0" ];
          nvidia.acceptLicense = true;
        };
      };
    };
  };

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      inherit (self.nixCfg.nixpkgs) config overlays;
    };
  };
}