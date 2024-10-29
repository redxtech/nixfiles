{ config, lib, pkgs, ... }:

let cfg = config.nas;
in {
  config = lib.mkIf cfg.enable {
    network.services.node-red = config.services.node-red.port;

    services.node-red = {
      enable = true;

      openFirewall = true;
      withNpmAndGcc = true;

      configFile = config.sops.secrets.node-red.path;
    };

    systemd.services.node-red.path = with pkgs; [
      bash
      git
      nodejs
      nodePackages.npm
    ];

    sops.secrets.node-red = {
      sopsFile = ../../secrets.yaml;
      mode = "0440";
      group = config.users.users.node-red.group;
    };
  };
}
