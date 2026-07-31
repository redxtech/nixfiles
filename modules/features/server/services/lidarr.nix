{ self, ... }:

{
  den.aspects.lidarr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels) mkHomepage;
    in
    {
      virtualisation.oci-containers.containers.lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        labels = mkHomepage {
          name = "lidarr";
          group = "arr";
          icon = "lidarr.svg";
          href = "https://lidarr.${config.networking.fqdn}";
          desc = "music downloader";
          weight = -100;
          widget = {
            type = "lidarr";
            url = "https://lidarr.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_LIDARR}}";
          };
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPorts 8686) ];
        volumes = [
          "${server.configRoot}/lidarr:/config"
          "${server.downloadsRoot}:/downloads"
          "${server.mediaRoot}:/media"
        ];
        networks = [ "host" ];
      };

      network.services.lidarr = 8686;
    };
}
