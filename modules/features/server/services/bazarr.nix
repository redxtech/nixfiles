{ self, ... }:

{
  den.aspects.bazarr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        labels = mkAllLabels "bazarr" {
          name = "bazarr";
          group = "arr";
          icon = "bazarr.svg";
          href = "https://bazarr.${config.networking.fqdn}";
          desc = "subtitles downloader";
          weight = -90;
          widget = {
            type = "bazarr";
            url = "https://bazarr.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_BAZARR}}";
          };
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPorts 6767) ];
        volumes = [
          "${server.configRoot}/bazarr:/config"
          "${server.mediaRoot}:/media"
        ];
      };
    };
}
