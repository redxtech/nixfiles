{ pkgs, lib, config, ... }:

let cfg = config.desktop;
in {
  options = let inherit (lib) mkOption types;
  in {
    desktop.audio = {
      devices = mkOption {
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              default = null;
              example = "Headphones";
              description = "The name of the audio device";
            };
            type = mkOption {
              type = types.enum [ "alsa" "bluetooth" ];
              default = "alsa";
              example = "Headphones";
              description = "The name of the audio device";
            };
            matches = mkOption {
              type = types.str;
              default = null;
              example = "alsa_output.pci-0000_1e_00*";
              description = "The glob to match against the devices";
            };
          };
        });
      };
    };
  };

  # write the wireplumber lua config files to rename the devices
  config = let
    mkDevice = { name, matches, ... }: ''
      {
        matches = [ { node.name = "~${matches}" } ]
        actions = { update-props = { node.description = "${name}" } }
      }
    '';
    alsa = builtins.filter (d: d.type == "alsa") cfg.audio.devices;
    bluetooth = builtins.filter (d: d.type == "bluetooth") cfg.audio.devices;
  in lib.mkIf cfg.enable {
    xdg.configFile."wireplumber/wireplumber.conf.d/51-alsa-rename.conf".text =
      lib.mkIf ((builtins.length cfg.audio.devices) != 0) ''
        monitor.alsa.rules = [
          ${lib.concatStringsSep "\n" (map mkDevice alsa)}
        ]

        monitor.bluez.rules = [
          ${lib.concatStringsSep "\n" (map mkDevice bluetooth)}
        ]
      '';
  };

}
