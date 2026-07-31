{ self, ... }:

{
  den.aspects.ladder.nixos = { config, ... }: {
    virtualisation.oci-containers.containers.ladder = {
      image = "wasimaster/13ft:latest";
      labels =
        let
          inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
        in
        mkAllLabels "ladder" {
          name = "13ft ladder";
          group = "utils";
          icon = "mdi-ladder";
          href = "https://ladder.${config.networking.fqdn}";
          desc = "home assistant dashboard";
        };
      ports = [ (self.lib.containers.mkPort 1313 5000) ];
    };
  };
}
