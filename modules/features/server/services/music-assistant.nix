{ self, ... }:

{
  den.aspects.music-assistant.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      port = 8095;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      network.services.mass = port;

      virtualisation.oci-containers.containers.mass = {
        image = "ghcr.io/music-assistant/server:latest";
        labels = mkAllLabels "mass" port {
          name = "music assistant";
          group = "home";
          icon = "sh-music-assistant.svg";
          href = "https://mass.${config.networking.fqdn}";
          desc = "music contoller";
          weight = -70;
        };
        ports = map mkPorts [
          port
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
        port
        8097
      ];
    };
}
