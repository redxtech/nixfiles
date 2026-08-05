{ self, ... }:

{
  den.aspects.sonarr.settings.secretsFile = self.lib.server.mkSecretsFileOption "Sonarr";

  den.aspects.sonarr.nixos =
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
        sonarr = {
          image = "lscr.io/linuxserver/sonarr:latest";
          labels = mkHomepage {
            name = "sonarr";
            group = "media";
            icon = "sonarr.svg";
            href = "https://sonarr.${config.networking.fqdn}";
            desc = "tv downloader";
            weight = -80;
            widget = {
              type = "sonarr";
              url = "https://sonarr.${config.networking.fqdn}";
              key = "{{HOMEPAGE_VAR_SONARR}}";
            };
          };
          inherit environment;
          ports = [ (mkPorts 8989) ];
          volumes = [
            "${server.configRoot}/sonarr:/config"
            "${server.downloadsRoot}:/downloads"
            "${server.mediaRoot}:/media"
          ];
          networks = [ "host" ];
        };

        sonarr-exportarr = {
          image = "ghcr.io/onedr0p/exportarr:v2.0";
          cmd = [ "sonarr" ];
          environment = environment // {
            PORT = "9707";
            URL = "https://sonarr.${config.networking.fqdn}";
          };
          environmentFiles = [ config.sops.secrets.exportarr_sonarr.path ];
          ports = [ (mkPorts 9707) ];
        };
      };

      monitoring.scrapeTargets.sonarr_exportarr = 9707;
      network.services.sonarr = 8989;
      sops.secrets.exportarr_sonarr.sopsFile = host.settings.sonarr.secretsFile;
    };
}
