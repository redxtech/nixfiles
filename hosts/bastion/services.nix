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
        image = "portainer/portainer-ce";
        ports = [ "8000:8000" "9000:9000" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "portainer-data:/data"
        ];
      };
    };
  };
}
