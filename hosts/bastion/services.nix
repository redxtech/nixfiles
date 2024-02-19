{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers = let
    mkPort = host: guest: "${toString host}:${toString guest}";
    mkPorts = port: "${toString port}:${toString port}";
    mkData = name:
      "${config.users.users.gabe.home}/Documents/pod-config/" + name + ":/data";
  in {
    backend = "docker";

    containers = {
      startpage = {
        image = "ghcr.io/redxtech/startpage";
        ports = [ "9009:3000" ];
      };

      portainer = {
        image = "portainer/portainer-ee:latest";
        ports = [ "8000:8000" (mkPorts 9000) ];
        volumes =
          [ "/var/run/docker.sock:/var/run/docker.sock" (mkData "portainer") ];
        extraOptions = [ "--network" "host" ];
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

  services.cockpit.settings.WebService.Origins = lib.concatStringsSep " " [
    "http://localhost:9090"
    "ws://localhost:9090"
    "http://bastion:9090"
    "ws://bastion:9090"
  ];
}
