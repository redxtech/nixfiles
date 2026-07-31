{
  den.aspects.grafana.nixos =
    { config, ... }:
    let
      port = 3000;
      secret = {
        sopsFile = ../../../../secrets/hosts/quasar/secrets.yaml;
        group = config.users.users.grafana.group;
        mode = "0440";
      };
    in
    {
      network.services.grafana = port;

      services.grafana = {
        enable = true;
        settings = {
          auth.oauth_allow_insecure_email_lookup = true;
          security.secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";

          server = {
            http_addr = "0.0.0.0";
            http_port = port;
            domain = "grafana.${config.networking.fqdn}";
            root_url = "https://grafana.${config.networking.fqdn}";
          };

          smtp = {
            enabled = true;
            from_address = "grafana@sucha.foo";
            host = "$__file{${config.sops.secrets.grafana_smtp_host.path}}";
            user = "$__file{${config.sops.secrets.grafana_smtp_user.path}}";
            password = "$__file{${config.sops.secrets.grafana_smtp_pw.path}}";
          };
        };
      };

      services.traefik.dynamicConfigOptions.http.routers.grafana.middlewares = [
        "homeassistant-allow-iframe"
      ];

      sops.secrets = {
        grafana_secret_key = secret;
        grafana_smtp_pw = secret;
        grafana_smtp_user = secret;
        grafana_smtp_host = secret;
      };
    };
}
