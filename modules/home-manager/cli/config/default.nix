{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    xdg.configFile = { "ente/config.yaml".source = ./ente.yaml; };

    sops.secrets.streamrip = {
      sopsFile = ../../../../home/gabe/secrets.yaml;
      path = "${config.xdg.configHome}/streamrip/config.toml";
      mode = "0740";
    };
  };
}
