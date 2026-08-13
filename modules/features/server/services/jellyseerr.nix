{ self, ... }:

{
  den.aspects.jellyseerr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      port = 5055;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkAllLabels "jellyseerr" port {
          name = "jellyseerr";
          group = "media";
          icon = "jellyseerr.svg";
          href = "https://jellyseerr.${config.networking.fqdn}";
          desc = "media request manager";
          weight = -60;
          widget = {
            type = "jellyseerr";
            url = "https://jellyseerr.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_JELLYSEERR}}";
          };
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPorts port) ];
        volumes = [ "${server.configRoot}/jellyseerr:/app/config" ];
        networks = [ "host" ];
      };
    };
}
