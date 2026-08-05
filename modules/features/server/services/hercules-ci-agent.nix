{ self, ... }:

{
  den.aspects.hercules-ci-agent.settings.secretsFile =
    self.lib.server.mkSecretsFileOption "Hercules CI agent";

  den.aspects.hercules-ci-agent.nixos =
    { config, host, ... }:
    let
      secretPath = name: config.sops.secrets."hercules-ci-agent-${name}".path;
      secret = {
        sopsFile = host.settings.hercules-ci-agent.secretsFile;
        owner = "hercules-ci-agent";
      };
    in
    {
      services.hercules-ci-agent = {
        enable = true;
        settings = {
          binaryCachesPath = secretPath "binary-caches";
          clusterJoinTokenPath = secretPath "join-token";
          secretsJsonPath = secretPath "secrets";
        };
      };

      sops.secrets = {
        hercules-ci-agent-binary-caches = secret;
        hercules-ci-agent-join-token = secret;
        hercules-ci-agent-secrets = secret;
      };
    };
}
