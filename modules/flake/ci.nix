{ self, lib, inputs, withSystem, ... }:

{
  imports = [ inputs.hercules-ci-effects.flakeModule ];

  hercules-ci = {
    flake-update = {
      enable = true;
      autoMergeMethod = "rebase";
      baseMerge.enable = true;
      when = {
        hour = [ 23 ];
        dayOfWeek = [ "Fri" ];
      };
      flakes = {
        "." = {
          commitSummary = "chore: update flake inputs";
          pullRequestTitle = "chore: update flake.lock";
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
}
