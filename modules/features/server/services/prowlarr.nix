{ self, ... }:

{
  den.aspects.prowlarr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabelsPort;
    in
    {
      virtualisation.oci-containers.containers.prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        labels = mkAllLabelsPort "prowlarr" 9696 {
          name = "prowlarr";
          group = "arr";
          icon = "prowlarr.svg";
          href = "https://prowlarr.${config.networking.fqdn}";
          desc = "arr indexer proxy";
          weight = -80;
          widget = {
            type = "prowlarr";
            url = "https://prowlarr.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_PROWLARR}}";
          };
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPort 9696 9696) ];
        volumes = [
          "${server.configRoot}/prowlarr:/config"
          "${server.downloadsRoot}:/downloads"
          "${server.mediaRoot}:/media"
        ];
        networks = [ "host" ];
      };
    };
}
