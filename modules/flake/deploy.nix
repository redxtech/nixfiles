{ self, lib, inputs, ... }:

{
  flake = {
    # deploy-rs
    deploy.nodes = builtins.mapAttrs (name: value: {
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

  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;

      mkNixOS = name:
        self.nixosConfigurations.${name}.config.system.build.toplevel;
      mkHome = name: self.homeConfigurations.${name}.activationPackage;
      mkAgent = name: isNixOS:
        cachix-deploy-lib.spec {
          agents.${name} = if isNixOS then mkNixOS name else mkHome name;
        };
    in {
      packages = {
        deploy-bastion = mkAgent "bastion" true;
        deploy-voyager = mkAgent "voyager" true;
        deploy-quasar = mkAgent "quasar" true;
        # deploy-deck = mkAgent "gabe@deck" false;

        deploy-all = cachix-deploy-lib.spec {
          agents = {
            bastion = mkNixOS "bastion";
            voyager = mkNixOS "voyager";
            quasar = mkNixOS "quasar";
            # deck = mkHome "gabe@deck";
          };
        };
      };

      apps = {
        # deploy via cachix-deploy with `nix run .#deploy`
        deploy = {
          type = "app";
          program = let
            deployScript = pkgs.writeShellApplication {
              name = "deploy";
              runtimeInputs = with pkgs; [ cachix ];
              text = ''
                spec=$(nix build ".#deploy-''${1-all}" --print-out-paths)
                cachix push gabedunn "$spec"
                cachix deploy activate "$spec"
              '';
            };
          in "${deployScript}/bin/deploy";
        };

        # deploy via deploy-rs with `nix run .#deploy-rs`
        deploy-rs = {
          type = "app";
          program = let
            deployScript = pkgs.writeShellApplication {
              name = "deploy-rs";
              runtimeInputs = with pkgs; [ deploy-rs ];
              text = ''
                deploy --targets ".#''${1-$(hostname)}"
              '';
            };
          in "${deployScript}/bin/deploy-rs";
        };

        # tag a deploy with `nix run .#tag-deploy`
        tag-deploy = {
          type = "app";
          program = let
            tagScript = pkgs.writeShellApplication {
              name = "tag-deploy";
              runtimeInputs = with pkgs; [ git ];
              # get the current date, and check if there are
              # any git tags that start with vyyyy-mm-dd.
              # if there aren't, then tag the current commit
              # with the format vyyyy-mm-dd-1. otherwise, increment
              # the number at the end of the tag. then push the tag
              text = ''
                date=$(date +%Y-%m-%d)
                tag=$(git tag -l "v$date-*" | tail -n 1)

                if [ -z "$tag" ]; then
                  tag="v$date-1"
                else
                  tag=$(echo "$tag" | awk -F- '{print $1"-"$2"-"$3"-"$4+1}')
                fi

                git tag "$tag" -m "$tag"
                git push origin "$tag"
              '';
            };
          in "${tagScript}/bin/tag-deploy";
        };
      };
    };
}
