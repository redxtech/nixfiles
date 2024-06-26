{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    programs.ssh = let
      user = "gabe";
      identityFile = "~/.ssh/id_ed25519";
      remoteForwards = [{
        bind.address = "/%d/.gnupg-sockets/S.gpg-agent";
        host.address = "/%d/.gnupg-sockets/S.gpg-agent.extra";
      }];
    in {
      enable = true;

      matchBlocks = let
        mkDevice = name: {
          user = user;
          identityFile = identityFile;
          hostname = "${name}.colobus-pirate.ts.net";
          forwardAgent = true;
          remoteForwards = remoteForwards;
        };
      in {
        "bastion" = mkDevice "bastion";
        "voyager" = mkDevice "voyager";
        "quasar" = mkDevice "quasar";
        "deck" = mkDevice "deck";
        "homeassistant" = {
          user = "hassio";
          identityFile = identityFile;
          hostname = "homeassistant";
        };
        "sb" = {
          user = "redxtech";
          identityFile = identityFile;
          hostname = "titan.usbx.me";
          forwardAgent = true;
          remoteForwards = remoteForwards;
        };
        rsync = {
          user = "fm1620";
          identityFile = identityFile;
          hostname = "fm1620.rsync.net";
        };
        "aur" = {
          user = "aur";
          identityFile = "~/.ssh/aur";
          # hostname = "titan.usbx.me";
        };
      };
    };
  };
}
