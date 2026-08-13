{ self, ... }:

{
  den.aspects.jackett.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      volumes = self.lib.server.volumes server;
      port = 9117;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.jackett = {
        image = "lscr.io/linuxserver/jackett:latest";
        labels = mkAllLabels "jackett" port {
          name = "jackett";
          group = "arr";
          icon = "jackett.svg";
          href = "https://jackett.${config.networking.fqdn}";
          desc = "arr indexer proxy";
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            AUTO_UPDATE = "true";
          };
        ports = [ (mkPorts port) ];
        volumes = [
          (volumes.config "jackett")
          volumes.allDownloads
        ];
      };
    };
}
