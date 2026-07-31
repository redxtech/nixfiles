{ self, ... }:

{
  den.aspects.espresense-companion.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.espresense-companion = {
        image = "espresense/espresense-companion:latest";
        labels = mkAllLabels "espc" {
          name = "espresense companion";
          group = "home";
          icon = "https://avatars.githubusercontent.com/u/89139441?s=200&v=4";
          href = "https://espc.${config.networking.fqdn}";
          desc = "room presence ui";
          weight = -70;
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = map mkPorts [
          8267
          8268
        ];
        volumes = [ "${server.configRoot}/espresense:/config/espresense" ];
      };
    };
}
