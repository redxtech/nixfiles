{ self, lib, inputs, ... }:

{
  flake = {
    # deploy-rs
    deploy.nodes = lib.mapAttrs (name: value: {
      hostname = name;
      sshUser = "root";
      fastConnection = false;
      remoteBuild = true;
      profiles.system.path =
        inputs.deploy-rs.lib.${value.pkgs.stdenv.system}.activate.nixos value;
    }) self.nixosConfigurations;

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy)
      inputs.deploy-rs.lib;
  };

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    packages.default = let
      cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;

      mkNixOS = name:
        self.nixosConfigurations.${name}.config.system.build.toplevel;
      mkHome = name: self.homeConfigurations.${name}.activationPackage;
    in cachix-deploy-lib.spec {
      agents = {
        bastion = mkNixOS "bastion";
        voyager = mkNixOS "voyager";
        deck = mkHome "gabe@deck";
      };
    };
  };
}
