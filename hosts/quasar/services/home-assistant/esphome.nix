{ config, lib, ... }:

let cfg = config.nas;
in {
  config = lib.mkIf cfg.enable {
    network.services.esphome = config.services.esphome.port;

    services.esphome = {
      enable = true;

      address = "0.0.0.0";
      openFirewall = true;
    };
  };
}
