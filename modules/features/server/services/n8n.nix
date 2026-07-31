{ self, ... }:

{
  den.aspects.n8n.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.n8n = {
        image = "docker.n8n.io/n8nio/n8n:latest";
        labels = mkAllLabels "n8n" {
          name = "n8n";
          group = "utils";
          icon = "n8n.svg";
          href = "https://n8n.${config.networking.fqdn}";
          desc = "workflow automation";
          weight = -90;
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            WEBHOOK_URL = "https://n8n.${config.networking.fqdn}";
            N8N_PORT = "5678";
            N8N_DATA_TABLES_MAX_SIZE_BYTES = "1073741824";
          };
        volumes = [ "${server.configRoot}/n8n:/home/node/.n8n" ];
      };
    };
}
