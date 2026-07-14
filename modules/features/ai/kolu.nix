{ inputs, ... }:

{
  den.aspects.kolu.homeManager =
    {
      inputs',
      config,
      osConfig,
      ...
    }:
    {
      imports = [ inputs.kolu.homeManagerModules.default ];

      services.kolu = {
        enable = true;
        package = inputs'.kolu.packages.default;

        # TODO: test allowed origins
        allowedOrigins = [
          "https://kolu.${osConfig.networking.fqdn}"
          "http://${osConfig.networking.hostName}:${toString config.services.kolu.port}"
        ];
      };
    };

  flake-file.inputs.kolu.url = "github:juspay/kolu";
}
