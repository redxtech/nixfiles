{ self, ... }:

{
  den.aspects.koinsight.nixos =
    { config, host, ... }:
    let
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.koinsight = {
        image = "ghcr.io/georgesg/koinsight:latest";
        labels = mkAllLabels "koinsight" {
          group = "books";
          icon = "mdi-book-information-variant";
          name = "koinsight";
          href = "https://koinsight.${config.networking.fqdn}";
          desc = "reading metrics";
          weight = -70;
        };
        ports = [ (mkPort 8820 3000) ];
        volumes = [ "${host.settings.server.configRoot}/koinsight:/app/data" ];
      };
    };
}
