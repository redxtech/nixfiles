{ self, ... }:

{
  den.aspects.github-runner.settings.secretsFile =
    self.lib.server.mkSecretsFileOption "GitHub runner";

  den.aspects.github-runner.nixos =
    {
      config,
      host,
      pkgs,
      ...
    }:
    {
      services.github-runners.system-builder = {
        enable = true;
        name = "system-builder";
        extraLabels = [ "system-builder" ];
        extraPackages = [ pkgs.cachix ];
        replace = true;
        user = config.users.users.github-runner.name;
        group = config.users.groups.github-runner.name;
        url = "https://github.com/redxtech/nixfiles";
        tokenFile = config.sops.secrets.ghrunner-system-builder.path;
      };

      users.users.github-runner = {
        isSystemUser = true;
        group = "github-runner";
      };
      users.groups.github-runner = { };

      nix.settings.trusted-users = [ "github-runner" ];

      sops.secrets.ghrunner-system-builder.sopsFile = host.settings.github-runner.secretsFile;
    };
}
