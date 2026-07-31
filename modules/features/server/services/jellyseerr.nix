{ self, ... }:

{
  den.aspects.jellyseerr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabelsPort;
    in
    {
      virtualisation.oci-containers.containers.jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        labels = mkAllLabelsPort "jellyseerr" 5055 {
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
        ports = [ (mkPort 5055 5055) ];
        volumes = [ "${server.configRoot}/jellyseerr:/app/config" ];
        networks = [ "host" ];
      };
    };
}
