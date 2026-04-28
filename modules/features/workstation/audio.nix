{ lib, ... }:

{
  den.aspects.audio = {
    settings = with lib.types; {
      devices = lib.mkOption {
        type = listOf (submodule {
          options = {
            name = lib.mkOption {
              type = str;
              default = null;
              example = "Headphones";
              description = "The name of the audio device";
            };
            type = lib.mkOption {
              type = enum [
                "alsa"
                "bluetooth"
              ];
              default = "alsa";
              description = "The type of the audio device";
            };
            matches = lib.mkOption {
              type = str;
              default = null;
              description = "The glob to match against the devices";
              example = "alsa_output.pci-0000_1e_00*";
            };
          };
        });
      };

      easyEffects = lib.mkEnableOption "Enables easyeffects";
    };

    homeManager =
      { host, config, ... }:
      let
        cfg = host.settings.audio;
      in
      {
        services.easyeffects.enable = cfg.easyEffects;

        # TODO: enable playerctld ??

        # write the wireplumber config file
        xdg.configFile."wireplumber/wireplumber.conf.d/51-alsa-rename.conf".text =
          let
            mkDevice =
              { name, matches, ... }:
              ''
                {
                  matches = [ { node.name = "~${matches}" } ]
                  actions = { update-props = { node.description = "${name}", node.nick = "${name}" } }
                }
              '';
            alsa = builtins.filter (d: d.type == "alsa") cfg.devices;
            bluetooth = builtins.filter (d: d.type == "bluetooth") cfg.devices;
          in
          lib.mkIf (builtins.length cfg.devices > 0) ''
            monitor.alsa.rules = [
              ${lib.concatStringsSep "\n" (map mkDevice alsa)}
            ]

            monitor.bluez.rules = [
              ${lib.concatStringsSep "\n" (map mkDevice bluetooth)}
            ]
          '';
      };
  };
}
