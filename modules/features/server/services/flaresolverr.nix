{ self, ... }:

{
  den.aspects.flaresolverr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        labels = mkAllLabels "flaresolverr" {
          name = "flaresolverr";
          group = "arr";
          icon = "flaresolverr.svg";
          href = "https://flaresolverr.${config.networking.fqdn}";
          desc = "cloudflare challenge resolver";
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            LOG_LEVEL = "info";
            LOG_HTML = "false";
            CAPTCHA_SOLVER = "none";
          };
        ports = [ (mkPorts 8191) ];
      };
    };
}
