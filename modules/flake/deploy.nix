{ self, inputs, ... }:

{
  # deploy-rs
  flake.deploy.nodes = builtins.mapAttrs (name: value: {
    hostname = name;
    sshUser = "root";
    fastConnection = true;
    remoteBuild = false;
    skipChecks = true;
    profiles.system.path =
      inputs.deploy-rs.lib.${value.pkgs.stdenv.system}.activate.nixos value;
  }) self.nixosConfigurations;

  perSystem = { config, self', inputs', pkgs, lib, system, ... }: {
    packages = let
      inherit (builtins) attrNames filter listToAttrs map;

      filteredHosts = filter (hostname: hostname != "nixiso")
        (attrNames self.nixosConfigurations);

      cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;

      mkAgent = name:
        cachix-deploy-lib.spec {
          agents.${name} =
            self.nixosConfigurations.${name}.config.system.build.toplevel;
        };

      agents = listToAttrs (map (hostname: {
        name = hostname;
        value = mkAgent hostname;
      }) filteredHosts);

      deploy-agents = listToAttrs (lib.mapAttrsToList (name: value: {
        name = "deploy-${name}";
        inherit value;
      }) agents);
    in deploy-agents // {
      deploy-all = cachix-deploy-lib.spec {
        agents = { inherit (agents) bastion voyager quasar; };
      };
    };

    # `nix run` deploy scripts
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
