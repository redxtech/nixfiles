{ self, ... }:

{
  den.aspects.qui.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.qui = {
        image = "ghcr.io/autobrr/qui:latest";
        labels = mkAllLabels "qui" {
          name = "qui";
          group = "download";
          icon = "qui.svg";
          href = "https://qui.${config.networking.fqdn}";
          desc = "qbit web interface";
          weight = -100;
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            QUI__PORT = "7476";
          };
        environmentFiles = [ config.sops.secrets.qui_env.path ];
        ports = [ (mkPorts 7476) ];
        volumes = [ ((self.lib.server.volumes server).config "qui") ];
      };

      sops.secrets.qui_env.sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
    };
}
