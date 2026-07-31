{ self, ... }:

{
  den.aspects.radarr.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      environment = self.lib.server.defaultEnvironment {
        uid = server.uid;
        gid = server.gid;
        timeZone = config.time.timeZone;
      };
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels) mkHomepage;
    in
    {
      virtualisation.oci-containers.containers = {
        radarr = {
          image = "lscr.io/linuxserver/radarr:latest";
          labels = mkHomepage {
            name = "radarr";
            group = "media";
            icon = "radarr.svg";
            href = "https://radarr.${config.networking.fqdn}";
            desc = "movie downloader";
            weight = -70;
            widget = {
              type = "radarr";
              url = "https://radarr.${config.networking.fqdn}";
              key = "{{HOMEPAGE_VAR_RADARR}}";
            };
          };
          inherit environment;
          ports = [ (mkPorts 7878) ];
          volumes = [
            "${server.configRoot}/radarr:/config"
            "${server.downloadsRoot}:/downloads"
            "${server.mediaRoot}:/media"
          ];
          networks = [ "host" ];
        };

        radarr-exportarr = {
          image = "ghcr.io/onedr0p/exportarr:v2.0";
          cmd = [ "radarr" ];
          environment = environment // {
            PORT = "9708";
            URL = "https://radarr.${config.networking.fqdn}";
          };
          environmentFiles = [ config.sops.secrets.exportarr_radarr.path ];
          ports = [ (mkPorts 9708) ];
        };
      };

      monitoring.scrapeTargets.radarr_exportarr = 9708;
      network.services.radarr = 7878;
      sops.secrets.exportarr_radarr.sopsFile = server.legacySopsFile;
    };
}
