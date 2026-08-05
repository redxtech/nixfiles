{ self, ... }:

{
  den.aspects.paperless.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers = {
        networks = [ "paperless" ];
        containers = {
          paperless = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
            labels = mkAllLabels "docs" {
              name = "paperless";
              group = "media";
              icon = "paperless.svg";
              href = "https://docs.${config.networking.fqdn}";
              desc = "document management";
              weight = -30;
              widget = {
                type = "paperlessngx";
                url = "https://docs.${config.networking.fqdn}";
                username = "{{HOMEPAGE_VAR_PAPERLESS_USER}}";
                password = "{{HOMEPAGE_VAR_PAPERLESS_PASS}}";
              };
            };
            environment =
              self.lib.server.defaultEnvironment {
                uid = server.uid;
                gid = server.gid;
                timeZone = config.time.timeZone;
              }
              // {
                PAPERLESS_URL = "https://docs.${config.networking.fqdn}";
                PAPERLESS_REDIS = "redis://paperless-redis:6379";
              };
            environmentFiles = [ config.sops.secrets.paperless_env.path ];
            ports = [ (mkPort 9200 8000) ];
            volumes = [
              "${server.configRoot}/paperless-ngx:/usr/src/paperless/data"
              "${server.dataRoot}/paperless-ngx/media:/usr/src/paperless/media"
              "${server.dataRoot}/paperless-ngx/consume:/usr/src/paperless/consume"
              "${server.dataRoot}/paperless-ngx/export:/usr/src/paperless/export"
            ];
            networks = [ "paperless" ];
          };

          paperless-redis = {
            image = "docker.io/library/redis:8";
            volumes = [ "${server.configRoot}/paperless-ngx-redis:/data" ];
            networks = [ "paperless" ];
          };
        };
      };

      sops.secrets.paperless_env.sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
    };
}
