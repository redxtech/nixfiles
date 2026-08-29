{
  den,
  lib,
  self,
  ...
}:

{
  den.aspects.tinyauth = {
    settings = {
      secretsFile = self.lib.server.mkSecretsFileOption "Tinyauth";

      pocketIdHostName = lib.mkOption {
        type = lib.types.str;
        default = "quasar";
        description = "Host name providing Pocket ID authentication.";
      };

      protectedServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Traefik file-provider routers protected by Tinyauth.";
      };
    };

    includes = [ den.aspects.network ];

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.tinyauth;
        middlewareName = "tinyauth";
        port = 3003;
        serviceName = "auth";
        appURL = "https://${serviceName}.${config.networking.fqdn}";
        pocketIdURL = "https://id.${cfg.pocketIdHostName}.${config.networking.domain}";
        unknownProtectedServices = lib.filter (
          name: !(config.network.finalServices ? ${name})
        ) cfg.protectedServices;
      in
      {
        assertions = [
          {
            assertion = unknownProtectedServices == [ ];
            message = "Tinyauth protectedServices contains unknown services: ${toString unknownProtectedServices}";
          }
          {
            assertion = !(lib.elem serviceName cfg.protectedServices);
            message = "Tinyauth cannot protect its own auth router.";
          }
        ];

        network.services.${serviceName} = port;

        services.tinyauth = {
          enable = true;
          environmentFile = config.sops.secrets.tinyauth_env.path;

          settings = {
            APPURL = appURL;
            LABELPROVIDER = "none";
            SERVER_ADDRESS = "127.0.0.1";
            SERVER_PORT = port;

            AUTH_SECURECOOKIE = true;
            AUTH_TRUSTEDPROXIES = "127.0.0.1/32";

            OAUTH_AUTOREDIRECT = "pocketid";
            OAUTH_PROVIDERS_POCKETID_AUTHURL = "${pocketIdURL}/authorize";
            OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";
            OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "${appURL}/api/oauth/callback/pocketid";
            OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
            OAUTH_PROVIDERS_POCKETID_TOKENURL = "${pocketIdURL}/api/oidc/token";
            OAUTH_PROVIDERS_POCKETID_USERINFOURL = "${pocketIdURL}/api/oidc/userinfo";
          };
        };

        services.traefik.dynamicConfigOptions.http = {
          middlewares.${middlewareName}.forwardAuth.address =
            "http://127.0.0.1:${toString port}/api/auth/traefik";

          routers = lib.genAttrs cfg.protectedServices (_: {
            middlewares = lib.mkAfter [ middlewareName ];
          });
        };

        sops.secrets.tinyauth_env = {
          sopsFile = cfg.secretsFile;
          group = config.services.tinyauth.group;
          mode = "0440";
        };
      };
  };
}
