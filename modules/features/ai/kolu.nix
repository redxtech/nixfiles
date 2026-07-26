{ inputs, ... }:

{
  den.aspects.kolu = {
    nixos.network.services.kolu = 7681;

    homeManager =
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

          host = "0.0.0.0";
          allowedOrigins = [
            "https://kolu.${osConfig.networking.fqdn}"
            "http://${osConfig.networking.hostName}:${toString config.services.kolu.port}"
          ];
        };
      };
  };

  flake-file.inputs.kolu.url = "github:juspay/kolu";
}
