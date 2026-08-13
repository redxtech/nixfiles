{ self, ... }:

{
  den.aspects.ladder.nixos =
    { config, ... }:
    let
      port = 5000;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.ladder = {
        image = "wasimaster/13ft:latest";
        labels = mkAllLabels "ladder" port {
          name = "13ft ladder";
          group = "utils";
          icon = "mdi-ladder";
          href = "https://ladder.${config.networking.fqdn}";
          desc = "home assistant dashboard";
        };
        ports = [ (self.lib.containers.mkPort 1313 port) ];
      };
    };
}
