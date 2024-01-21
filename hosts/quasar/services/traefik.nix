{ config, pkgs, lib, ... }:

with lib; {
  services.traefik = {
    enable = true;

    dataDir = cfg.paths.data + "/traefik";

    dynamicConfigOptions = {
      http = {
        routers = {
          router1 = {
            rule = "Host(`localhost`)";
            service = "service1";
          };
        };

        services = {
          service1 = {
            loadBalancer = { servers = [{ url = "http://localhost:8080"; }]; };
          };
        };
      };
    };
  };
}
