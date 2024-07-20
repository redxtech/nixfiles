{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    services = {
      darkman = { enable = false; };
      gnome-keyring = { enable = false; };
      # gpg-agent = { enable = false; };
      ssh-agent = { enable = false; };
    };
  };
}
