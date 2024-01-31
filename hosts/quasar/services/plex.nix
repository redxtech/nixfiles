{ config, pkgs, lib, ... }:

with lib;
let cfg = config.nas;
in {
  services = {
    plex = {
      enable = true;
      package = pkgs.plexPass;

      user = cfg.user;
      group = cfg.group;

      dataDir = "${cfg.paths.config}/plex";
      openFirewall = true;

      extraPlugins = [
        # (builtins.path {
        #   name = "Sub-Zero.bundle";
        #   path = pkgs.fetchFromGitHub {
        #     owner = "pannal";
        #     repo = " Sub-Zero.bundle";
        #     rev = "4ced7d8c8f9f5fb47d12410f87fa33d782e9f0f4";
        #     sha256 = "";
        #   };
        # })
        # (builtins.path {
        #   name = "Youtube-DL-Agent.bundle";
        #   path = pkgs.fetchFromGitHub {
        #     owner = "djdembeck";
        #     repo = "Youtube-DL-Agent.bundle";
        #     rev = "8f6b96180f4cae62978cb364b9e76e7892a4a508";
        #     sha256 = "";
        #   };
        # })
      ];

      extraScanners = [
        # (fetchFromGitHub {
        #   owner = "ZeroQI";
        #   repo = "Absolute-Series-Scanner";
        #   rev = "ee10f5ce4b6d356fd1c73eea377f96e102924f9b";
        #   sha256 = "";
        # })
      ];
    };

    # TODO: kitana web UI ?
  };

  services.traefik.dynamicConfigOptions.http =
    lib.mkIf config.services.traefik.enable {
      routers.plex = {
        rule = "Host(`plex.${config.nas.domain}`)";
        service = "plex";
        entrypoints = [ "websecure" ];
      };
      services.plex.loadBalancer.servers =
        [{ url = "http://localhost:${toString config.nas.ports.plex}"; }];
    };
}
