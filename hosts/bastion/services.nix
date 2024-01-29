{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      startpage = {
        image = "ghcr.io/redxtech/startpage";
        ports = [ "9009:3000" ];
      };

      portainer = {
        image = "portainer/portainer-ee";
        ports = [ "8000:8000" "9000:9000" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/var/run/portainer:/data"
        ];
        extraOptions = [ "--network=host" ];
      };

      portainer-agent = {
        image = "portainer/agent:2.19.4";
        ports = [ "9001:9001" ];
        volumes = [
          "/var/lib/docker/volumes:/var/lib/docker/volumes"
          "/var/run/docker.sock:/var/run/docker.sock"
          "/:/host"
        ];
        extraOptions = [ "--network=host" ];
      };
    };
  };
}
