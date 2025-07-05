{ self, inputs, lib, ... }:

{
  flake = {
    nixCfg = {
      nix = {
        settings = {
          trusted-users = [ "root" "@wheel" "gabe" ];
          experimental-features = [ "nix-command" "flakes" ];
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://gabedunn.cachix.org"
            "https://hyprland.cachix.org"
            # "https://cache.garnix.io"
            # "https://devenv.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "gabedunn.cachix.org-1:wLWTKadNjpr2Op3rBnDZMUmUEPPIoKG87oY4PmBP8qU="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
            # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          ];
          auto-optimise-store = lib.mkDefault true;
          warn-dirty = false;
          system-features = [ "kvm" "big-parallel" "nixos-test" ];
          allow-import-from-derivation = true;
					download-buffer-size = 1073741824;
        };

        # add each flake input as a registry
        # to make nix3 commands consistent with the flake
        registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      };

      nixpkgs = {
        overlays = builtins.attrValues self.overlays;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-33.4.11" ];
          nvidia.acceptLicense = true;
        };
      };
    };
  };

  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      pkgArgs = {
        inherit system;
        inherit (self.nixCfg.nixpkgs) config overlays;
      };
    in {
      _module.args.pkgs = import inputs.nixpkgs pkgArgs;
      _module.args.stable = import inputs.nixpkgs-stable pkgArgs;
      _module.args.small = import inputs.nixpkgs-small pkgArgs;
    };
}
