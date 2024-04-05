{ self, lib, inputs, withSystem, ... }:

{
  imports = [ inputs.hci-effects.flakeModule ];

  hercules-ci = {
    flake-update = {
      enable = true;
      baseMerge.enable = true;
      baseMerge.method = "rebase";
      pullRequestTitle = "chore: update flake.lock";
      when = {
        hour = [ 0 ];
        dayOfWeek = [ "Fri" ];
      };
      flakes = {
        "." = {
          commitSummary = "chore: update flake inputs";
          inputs = [
            "nixpkgs"
            "home-manager"
            "hardware"
            "nixos-generators"
            "neovim-nightly-overlay"
            "devenv"
            "deploy-rs"
            "rust-overlay"
          ];
        };
      };
    };
  };

  herculesCI = { herculesCI, ... }: {
    ciSystems = [ "x86_64-linux" ];

    onPush.default.outputs.effects = withSystem "x86_64-linux"
      ({ config, hci-effects, pkgs, inputs', ... }:
        let
          inherit (hci-effects) runIf runNixOS;
          inherit (builtins) length match;
          shouldDeploy = length (match "deploy-(.*)" herculesCI.repo.tag) != 0;
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
