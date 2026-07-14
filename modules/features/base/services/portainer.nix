{ self, lib, ... }:

{
  den.aspects.portainer = {
    nixos =
      {
        host,
        config,
        pkgs,
        ...
      }:
      {
        virtualisation.oci-containers.containers =
          let
            inherit (config.networking) fqdn;
            inherit (self.lib.containers) mkPorts;
            inherit (self.lib.containers.labels.traefik fqdn) mkAllLabelsPort;

            cfg = host.settings.base;

            mkData =
              name: "${config.users.users.${cfg.primaryUser}.home}/Documents/pod-config/" + name + ":/data";
          in
          {
            portainer = {
              image = "portainer/portainer-ee:latest";
              labels = mkAllLabelsPort "portainer" 9000 {
                name = "portainer";
                group = "admin";
                icon = "portainer.svg";
                href = "https://portainer.${fqdn}";
                desc = "docker management interface";
                weight = -90;
                widget = {
                  type = "portainer";
                  url = "https://portainer.${fqdn}";
                  env = "3";
                  key = "{{HOMEPAGE_VAR_PORTAINER}}";
                };
              };
              ports = [
                "8000:8000"
                (mkPorts 9000)
              ];
              volumes = [
                "/var/run/docker.sock:/var/run/docker.sock"
                (mkData "portainer")
              ];
              extraOptions = [
                "--network"
                "host"
              ];
            };

            portainer-agent = {
              image = "portainer/agent:latest";
              ports = [ (mkPorts 9001) ];
              volumes = [
                "/var/lib/docker/volumes:/var/lib/docker/volumes"
                "/var/run/docker.sock:/var/run/docker.sock"
                "/:/host"
              ];
            };
          };
      };
  };
}
