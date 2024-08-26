{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nas;
  cfgNet = config.network;
in {
  services = {
    plex = {
      enable = true;
      package = pkgs.plexPass;

      inherit (cfg) group user;

      dataDir = "${cfg.paths.config}/plex";
      openFirewall = true;
    };

    # TODO: kitana web UI ?
  };

  services.traefik.dynamicConfigOptions.http =
    lib.mkIf config.services.traefik.enable {
      routers.plex = {
        rule = "Host(`plex.${cfgNet.address}`)";
        service = "plex";
        entrypoints = [ "websecure" ];
      };
      services.plex.loadBalancer.servers =
        [{ url = "http://localhost:${toString config.nas.ports.plex}"; }];
    };
}
