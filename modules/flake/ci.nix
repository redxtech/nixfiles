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

  herculesCI = { hci-effects, branch, ... }: {
    ciSystems = [ "x86_64-linux" ];
  };

  flake.effects = { branch, ... }:
    withSystem "x86_64-linux" ({ config, hci-effects, pkgs, inputs', ... }: {
      deploy = hci-effects.runIf (branch == "master") hci-effects.runNixOS {
        name = "bastion-build";
        configuration = self.nixosConfigurations.bastion;
        secretsMap.ssh = "default-ssh";
        ssh.destination = "bastion";
      };
    });

}