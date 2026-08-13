{ self, ... }:

{
  den.aspects.unpoller.settings.secretsFile = self.lib.server.mkSecretsFileOption "UniFi Poller";

  den.aspects.unpoller.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      port = 9130;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      monitoring.scrapeTargets.unpoller = port;

      virtualisation.oci-containers.containers.unpoller = {
        image = "ghcr.io/unpoller/unpoller:latest";
        labels = mkAllLabels "unpoller" port {
          name = "unpoller";
          group = "services";
          icon = "https://i.imgur.com/VBHV26V.png";
          href = "https://unpoller.${config.networking.fqdn}";
          desc = "unifi device poller";
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            UP_UNIFI_DEFAULT_URL = "https://unifi";
            UP_INFLUXDB_DISABLE = "true";
            UP_UNIFI_DEFAULT_SAVE_DPI = "true";
          };
        environmentFiles = [ config.sops.secrets."unpoller.env".path ];
        ports = [ (mkPorts port) ];
        volumes = [ ((self.lib.server.volumes server).config "unpoller") ];
      };

      sops.secrets."unpoller.env".sopsFile = host.settings.unpoller.secretsFile;
    };
}
