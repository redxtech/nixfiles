{ self, ... }:

{
  den.aspects.bento.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.bento = {
        image = "bentopdf/bentopdf:latest";
        labels = mkAllLabels "bento" {
          name = "bento";
          group = "utils";
          icon = "bentopdf.svg";
          href = "https://bento.${config.networking.fqdn}";
          desc = "bento";
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPort 8282 8080) ];
      };
    };
}
