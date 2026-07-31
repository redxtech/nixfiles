{ self, ... }:

{
  den.aspects.actual.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.actual = {
        image = "ghcr.io/actualbudget/actual:latest";
        labels = mkAllLabels "actual" {
          name = "actual";
          group = "utils";
          icon = "actual-budget.svg";
          href = "https://actual.${config.networking.fqdn}";
          desc = "actual budget";
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPorts 5006) ];
        volumes = [ ((self.lib.server.volumes server).config "actual") ];
      };
    };
}
