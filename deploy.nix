{ self, lib, inputs, ... }:

{
  flake = {
    # deploy-rs
    deploy.nodes = lib.mapAttrs (name: value: {
      hostname = name;
      sshUser = "gabe";
      fastConnection = true;
      profiles.system = {
        user = "root";
        path =
          inputs.deploy-rs.lib.${value.pkgs.stdenv.system}.activate.nixos value;
      };
      remoteBuild = true;
    }) self.nixosConfigurations;

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy)
      inputs.deploy-rs.lib;
  };

  perSystem = { config, self', inputs', pkgs, system, ... }:
    {
      # packages = {
      #   default = let cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
      #   in cachix-deploy-lib.spec {
      #     agents = let
      #       common = [ ./hosts/common ]
      #         ++ (builtins.attrValues (import ./modules/nixos));
      #     in {
      #       bastion = cachix-deploy-lib.nixos ([ ./hosts/bastion ] ++ common);
      #     };
      #   };
      # };
    };
}
