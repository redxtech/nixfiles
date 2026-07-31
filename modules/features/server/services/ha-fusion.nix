{ self, ... }:

{
  den.aspects.ha-fusion.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.ha-fusion = {
        image = "ghcr.io/matt8707/ha-fusion:latest";
        labels = mkAllLabels "fusion" {
          name = "ha fusion";
          group = "home";
          icon = "https://raw.githubusercontent.com/matt8707/addon-ha-fusion/refs/heads/main/icon.png";
          href = "https://fusion.${config.networking.fqdn}";
          desc = "home assistant dashboard";
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            HASS_URL = "https://ha.${config.networking.fqdn}";
          };
        volumes = [ "${server.configRoot}/ha-fusion:/app/data" ];
        ports = [ (mkPorts 5050) ];
      };
    };
}
