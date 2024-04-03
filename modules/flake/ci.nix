{ self, lib, inputs, withSystem, ... }:

{
  imports = [ inputs.hci-effects.flakeModule ];

  hercules-ci = {
    flake-update = {
      enable = true;
      baseMerge.enable = true;
      baseMerge.method = "rebase";
      when = {
        hour = [ 0 ];
        dayOfWeek = [ "Fri" ];
      };
      flakes = {
        "." = {
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

          commitSummary = "chore: update flake inputs";
          pullRequestTitle = "chore: update flake.lock";
        };
      };
    };
  };

  herculesCI = {
    ciSystems = [ "x86_64-linux" ];

    onPush.default.outputs.effects = { tag ? "", ... }:
      withSystem "x86_64-linux" ({ config, hci-effects, pkgs, inputs', ... }:
        let
          inherit (hci-effects) runIf runNixOS;
          isDeploy = (builtins.match "deploy-(.*)" tag) != null;
        in {
          deploy-bastion = runIf isDeploy (runNixOS {
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
