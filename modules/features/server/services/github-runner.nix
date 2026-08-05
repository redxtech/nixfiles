{ self, ... }:

{
  den.aspects.github-runner.settings.secretsFile =
    self.lib.server.mkSecretsFileOption "GitHub runner";

  den.aspects.github-runner.nixos =
    { config, host, ... }:
    {
      services.github-runners.system-builder = {
        enable = true;
        name = "system-builder";
        url = "https://github.com/redxtech/nixfiles";
        tokenFile = config.sops.secrets.ghrunner-system-builder.path;
      };

      sops.secrets.ghrunner-system-builder.sopsFile = host.settings.github-runner.secretsFile;
    };
}
