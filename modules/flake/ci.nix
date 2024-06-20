{ self, lib, inputs, withSystem, ... }:

{
  imports = [ inputs.hci-effects.flakeModule ];

  hercules-ci = {
    flake-update = let
      primaryInputs = [
        "nixpkgs"
        "home-manager"
        "flake-parts"
        "cachix-deploy-flake"
        "disko"
        "nixos-generators"
        "sops-nix"
      ];
      secondaryInputs = [
        "attic"
        "deploy-rs"
        "devenv"
        "fh"
        "flake-schemas"
        "hardware"
        "hci-effects"
        "neovim-nightly"
        "nix-flatpak"
        "rust-overlay"
        "spicetify-nix"
        "swww"
        "xremap-flake"
      ];
    in {
      enable = true;
      baseMerge.enable = true;
      baseMerge.method = "rebase";
      createPullRequest = true;
      pullRequestTitle = "chore: update flake.lock";
      pullRequestBody = ''
        update `flake.lock`. see the commit message(s) for details.

        updated flake inputs:
        ${builtins.concatStringsSep "\n"
        (map (i: "	- ${i}") (primaryInputs ++ secondaryInputs))}

        you may reset this branch by deleting it and re-running the update job.

            git push origin :flake-update
      '';
      flakes = {
        "." = {
          commitSummary = "chore: update flake inputs";
          inputs = (primaryInputs ++ secondaryInputs);
        };
      };
      when = {
        hour = [ 8 ];
        dayOfWeek = [ "Fri" ];
      };
    };
  };

  herculesCI = {
    ciSystems = [ "x86_64-linux" ];

    onPush.default.outputs.effects = withSystem "x86_64-linux"
      ({ config, hci-effects, pkgs, inputs', ... }:
        let
          inherit (hci-effects) runIf runNixOS;
          inherit (builtins) length match;
          shouldDeploy = false;
          # temp disable until i can figure out how to get the tag
          # shouldDeploy = length (match "deploy-(.*)" herculesCI.repo.tag) != 0;
        in {
          deploy-bastion = runIf shouldDeploy (runNixOS {
            name = "deploy-bastion";
            configuration = self.nixosConfigurations.bastion;
            secretsMap.ssh = "default-ssh";
            ssh.destination = "bastion.colobus-pirate.ts.net";
            userSetupScript = ''
              writeSSHKey ssh
              cat >>~/.ssh/known_hosts <<EOF
              bastion.colobus-pirate.ts.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMH9M36ujLFPqB/3cksmux1MAq+fHUw3tq8ORZ7uPcW/
              EOF
            '';
          });
        });
  };
}
