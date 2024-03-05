{ inputs, pkgs, lib, config, ... }:

{
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
    mkDevice = { name, matches }: ''
      table.insert(alsa_monitor.rules, {
        matches = { { { "node.name", "matches", "${matches}" } } },
        apply_properties = { ["node.description"] = "${name}" },
      })
    '';
  in {
    xdg.configFile."wireplumber/main.lua.d/51-alsa-rename.lua".text = ''
      ${lib.concatStringsSep "\n" (map mkDevice config.desktop.audio.devices)}
    '';
  };

}
