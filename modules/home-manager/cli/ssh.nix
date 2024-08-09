{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    programs.ssh = let
      user = "gabe";
      identityFile = "~/.ssh/id_rsa_yubikey.pub";
      remoteForwards = [{
        bind.address = "/%d/.gnupg-sockets/S.gpg-agent";
        host.address = "/%d/.gnupg-sockets/S.gpg-agent.extra";
      }];
    in {
      enable = true;

      matchBlocks = let
        mkDevice = name: {
          inherit identityFile remoteForwards user;
          hostname = "${name}.colobus-pirate.ts.net";
          forwardAgent = true;
        };
      in {
        bastion = mkDevice "bastion";
        voyager = mkDevice "voyager";
        quasar = mkDevice "quasar";
        deck = mkDevice "deck";
        homeassistant = {
          inherit identityFile;
          user = "hassio";
          hostname = "homeassistant";
        };
        sb = {
          inherit identityFile remoteForwards;
          user = "redxtech";
          hostname = "titan.usbx.me";
          forwardAgent = true;
        };
        rsync = {
          inherit identityFile;
          user = "fm1620";
          hostname = "fm1620.rsync.net";
        };

        # external services
        "aur.archlinux.org" = {
          user = "aur";
          identityFile = "~/.ssh/aur.pub";
        };
        "github.com" = {
          inherit identityFile;
          identitiesOnly = true;
        };
      };
    };
  };
}
