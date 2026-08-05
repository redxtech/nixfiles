{
  den.aspects.pocket-id.nixos =
    { config, host, ... }:
    let
      port = 1411;
    in
    {
      network.services.id = port;

      services.pocket-id = {
        enable = true;
        environmentFile = config.sops.secrets.pocket_id_env.path;

        settings = {
          APP_URL = "https://id.${config.networking.fqdn}";
          TRUST_PROXY = true;
          PORT = port;

          EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
          EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
          EMAIL_API_KEY_EXPIRATION_ENABLED = true;

          METRICS_ENABLED = true;
        };
      };

      sops.secrets.pocket_id_env = {
        sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
        group = config.services.pocket-id.group;
        mode = "440";
      };
    };
}
