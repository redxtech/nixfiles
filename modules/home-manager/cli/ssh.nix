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
        # default options for all hosts
        mkHost = args:
          {
            inherit identityFile user;
            identitiesOnly = true;
          } // args;

        # options for my personal devices
        mkDevice = name:
          mkHost {
            inherit remoteForwards;
            hostname = "${name}.colobus-pirate.ts.net";
            # forwardX11 = true;
            # forwardX11Trusted = true;
          };
      in {
        bastion = mkDevice "bastion";
        voyager = mkDevice "voyager";
        quasar = mkDevice "quasar";
        deck = mkDevice "deck";
        homeassistant = mkHost {
          user = "hassio";
          hostname = "homeassistant";
        };
        sb = mkHost {
          user = "redxtech";
          hostname = "titan.usbx.me";
        };
        rsync = mkHost {
          user = "fm1620";
          hostname = "fm1620.rsync.net";
        };

        # external services
        "aur.archlinux.org" = mkHost {
          user = "aur";
          identityFile = "~/.ssh/aur.pub";
        };
        "github.com" = mkHost { };
      };
    };

    # ensure public keys are present
    home.file = {
      ".ssh/id_rsa_yubikey.pub".source = ../../../home/gabe/keys/gpg.pub;
      ".ssh/id_ed25519.pub".source = ../../../home/gabe/keys/ssh.pub;
    };
  };
}
