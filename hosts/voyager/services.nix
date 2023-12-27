{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      startpage = {
        image = "ghcr.io/redxtech/startpage";
        ports = [ "9009:3000" ];
      };
    };
  };
}
