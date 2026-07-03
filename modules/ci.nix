{ inputs, ... }:

{
  imports = [ inputs.hci-effects.flakeModule ];

  hercules-ci = {
    flake-update = {
      enable = true;
      baseMerge.enable = true;
      baseMerge.method = "rebase";
      createPullRequest = true;
      pullRequestTitle = "chore: update flake.lock";
      pullRequestBody = ''
        update `flake.lock`. see the commit message(s) for details.

        updated flake inputs.

        you may reset this branch by deleting it and re-running the update job.

            git push origin :flake-update
      '';
      flakes.".".commitSummary = "chore: update flake inputs";
      when = {
        hour = [ 8 ];
        dayOfWeek = [ "Fri" ];
      };
    };
  };

  flake-file.inputs.hci-effects = {
    url = "github:hercules-ci/hercules-ci-effects";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
