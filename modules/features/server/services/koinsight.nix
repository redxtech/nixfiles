{ self, ... }:

{
  den.aspects.koinsight.nixos =
    { config, host, ... }:
    let
      port = 3000;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels mkTLRstr;
    in
    {
      virtualisation.oci-containers.containers.koinsight = {
        image = "ghcr.io/georgesg/koinsight:latest";
        labels =
          mkAllLabels "koinsight" port {
            group = "books";
            icon = "mdi-book-information-variant";
            name = "koinsight";
            href = "https://koinsight.${config.networking.fqdn}";
            desc = "reading metrics";
            weight = -70;
          }
          // {
            "${mkTLRstr "koinsight"}.middlewares" = "tinyauth@file";
          };
        ports = [ (mkPort 8820 port) ];
        volumes = [ "${host.settings.server.configRoot}/koinsight:/app/data" ];
      };
    };
}
