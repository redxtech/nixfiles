{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nas;
  mkNtv = conf: mkIf (!cfg.useNative) conf;
in {
  services = {
    plex = {
      enable = true;
      package = pkgs.plexPass;

      user = cfg.user;
      group = cfg.group;

      dataDir = "${cfg.paths.data}/plex";
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

    tautulli = mkNtv {
      enable = true;

      user = cfg.user;
      group = cfg.group;

      dataDir = "${cfg.paths.data}/tautulli";
      configFile = cfg.paths.config + "/tautulli/config.ini";

      port = cfg.ports.tautulli;
      openFirewall = true;
    };

    # TODO: kitana web UI ?
  };
}
