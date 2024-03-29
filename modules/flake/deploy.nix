{ self, lib, inputs, ... }:

{
  flake = {
    # deploy-rs
    deploy.nodes = lib.mapAttrs (name: value: {
      hostname = name;
      sshUser = "root";
      fastConnection = true;
      remoteBuild = true;
      profiles.system.path =
        inputs.deploy-rs.lib.${value.pkgs.stdenv.system}.activate.nixos value;
    }) self.nixosConfigurations;

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy)
      inputs.deploy-rs.lib;
  };

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    packages.default =
      let cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
      in cachix-deploy-lib.spec {
        agents = {
          bastion = cachix-deploy-lib.nixos self.nixosModules.bastion;
        };
      };
  };
}
