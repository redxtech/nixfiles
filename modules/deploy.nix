{ inputs, self, ... }:

{
  # deploy-rs

  flake.deploy.nodes = builtins.mapAttrs (name: value: {
    hostname = name;
    sshUser = "root";
    fastConnection = true;
    remoteBuild = false;
    skipChecks = true;
    profiles.system.path =
      inputs.deploy-rs.lib.${value.pkgs.stdenv.hostPlatform.system}.activate.nixos
        value;
  }) self.nixosConfigurations;

  perSystem =
    {
      inputs',
      pkgs,
      lib,
      ...
    }:
    {
      apps.deploy = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "deploy";
            runtimeInputs = [ inputs'.deploy-rs.packages.deploy-rs ];
            text = ''
              deploy --targets ".#''${1-$(hostname)}"
            '';
          }
        );
      };
    };

  flake-file.inputs.deploy-rs = {
    url = "github:serokell/deploy-rs";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
