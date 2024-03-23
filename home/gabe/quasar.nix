{ pkgs, lib, config, ... }:

{
  imports = [ ./global ./features/desktop/gnome ];

  # rename wireplumber devices
  # xdg.configFile."wireplumber/main.lua.d/51-alsa-rename.lua".text = ''
  #   table.insert(alsa_monitor.rules, {
  #     matches = { { { "node.name", "matches", "alsa_output.usb-Schiit_Audio_Schiit_Unison_Modi_Multi_2-00.*" } } },
  #     apply_properties = { ["node.description"] = "Schiit Stack" },
  #   })
  # '';
}
