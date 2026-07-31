{ self, ... }:

{
  den.aspects.signaturepdf.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.signaturepdf = {
        image = "ghcr.io/redxtech/signaturepdf:master";
        labels = mkAllLabels "pdf" {
          name = "pdf";
          group = "utils";
          icon = "mdi-signature";
          href = "https://pdf.${config.networking.fqdn}";
          desc = "pdf signing and other tools";
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            SERVERNAME = "pdf.${config.networking.fqdn}";
            UPLOAD_MAX_FILESIZE = "64M";
            POST_MAX_SIZE = "64M";
            DEFAULT_LANGUAGE = "en_CA.UTF-8";
            PDF_STORAGE_ENCRYPTION = "true";
          };
        ports = [ (mkPort 9208 80) ];
        volumes = [ ((self.lib.server.volumes server).data "pdf") ];
      };
    };
}
