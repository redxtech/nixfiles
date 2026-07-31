{ self, ... }:

{
  den.aspects.music-assistant.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabelsPort;
    in
    {
      network.services.mass = 8095;

      virtualisation.oci-containers.containers.mass = {
        image = "ghcr.io/music-assistant/server:latest";
        labels = mkAllLabelsPort "mass" 8095 {
          name = "music assistant";
          group = "home";
          icon = "sh-music-assistant.svg";
          href = "https://mass.${config.networking.fqdn}";
          desc = "music contoller";
          weight = -70;
        };
        ports = map mkPorts [
          8095
          8097
          5090
          5091
          3483
        ];
        volumes = [
          "${server.configRoot}/music-assistant-server:/data"
          "${server.mediaRoot}:/media"
        ];
        extraOptions = [
          "--privileged"
          "--network"
          "host"
        ];
      };

      networking.firewall.allowedTCPPorts = [
        8095
        8097
      ];
    };
}
