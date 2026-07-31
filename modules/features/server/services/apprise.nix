{ self, ... }:

{
  den.aspects.apprise.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.apprise = {
        image = "lscr.io/linuxserver/apprise-api:latest";
        labels = mkAllLabels "apprise" {
          name = "apprise";
          group = "services";
          icon = "mdi-bullhorn";
          href = "https://apprise.${config.networking.fqdn}";
          desc = "notification service";
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPort 9005 8000) ];
        volumes = [ ((self.lib.server.volumes server).config "apprise") ];
      };
    };
}
