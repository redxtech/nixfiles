{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    xdg.configFile = {
      "ente/config.yaml".source = ./ente.yaml;
      "lyrics-in-terminal/lyrics.cfg".source = ./lyrics.cfg;
    };

    sops.secrets.streamrip = {
      sopsFile = ../../../../home/gabe/secrets.yaml;
      path = "${config.xdg.configHome}/streamrip/config.toml";
      mode = "0740";
    };
  };
}
