{ config, lib, ... }:

let cfg = config.nas;
in {
  config = lib.mkIf cfg.enable {
    network.services.node-red = config.services.node-red.port;

    services.node-red = {
      enable = true;

      openFirewall = true;
      withNpmAndGcc = true;
    };
  };
}
