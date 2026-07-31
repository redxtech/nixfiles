{ self, lib, ... }:

{
  den.aspects.portainer = {
    settings.dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Persistent Portainer data directory, or null to use the primary user's home.";
    };

    nixos =
      {
        host,
        config,
        ...
      }:
      let
        inherit (config.networking) fqdn;
        inherit (self.lib.containers) mkPorts;
        inherit (self.lib.containers.labels.traefik fqdn) mkAllLabelsPort;

        base = host.settings.base;
        cfg = host.settings.portainer;
        dataDir =
          if cfg.dataDir != null then
            cfg.dataDir
          else
            "${config.users.users.${base.primaryUser}.home}/Documents/pod-config/portainer";
      in
      {
        virtualisation.oci-containers.containers = {
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
              "${dataDir}:/data"
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
