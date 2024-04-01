{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    xdg.configFile = { "lyrics-in-terminal/lyrics.cfg".source = ./lyrics.cfg; };
  };
}
