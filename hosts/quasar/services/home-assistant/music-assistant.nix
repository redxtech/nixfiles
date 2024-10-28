{ config, self, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (self.lib.containers) mkPorts;
  inherit (self.lib.containers.labels.traefik cfgNet.address) mkAllLabelsPort;
in {
  config = {
    network.services.mass = 8095;

    virtualisation.oci-containers.containers.mass = {
      image = "ghcr.io/music-assistant/server:latest";
      labels = mkAllLabelsPort "mass" cfg.ports.music-assistant {
        name = "music assistant";
        group = "home";
        icon = "sh-music-assistant.svg";
        href = "https://mass.${cfgNet.address}";
        desc = "music contoller";
        weight = -70;
      };
      ports = map mkPorts [ cfg.ports.music-assistant 8097 5090 5091 3483 ];
      volumes = [
        "${cfg.paths.config}/music-assistant-server:/data"
        "${cfg.paths.media}:/media"
      ];
      extraOptions = [ "--privileged" "--network" "host" ];
    };

    networking.firewall.allowedTCPPorts = [ 8095 8097 ];
  };
}
