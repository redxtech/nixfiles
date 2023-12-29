{ inputs, outputs, ... }:

{
  imports = [
    ./global
    # ./features/desktop/wireless
  ];

  colorscheme = inputs.nix-colors.colorSchemes.atelier-heath;
  wallpaper = outputs.wallpapers.aenami-lunar;

  #   ------
  #  | eDP-1|
  #   ------
  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];

  # desktop layout
  xsession.windowManager.bspwm = {
    monitors = { "eDP-1" = [ "shell" "www" "chat" "music" "files" "video" ]; };
  };

  xdg.configFile."wireplumber/main.lua.d/51-alsa-rename.lua".text = ''
    table.insert(alsa_monitor.rules, {
      matches = { { { "node.name", "matches", "alsa_output.pci-0000_00_1f.3.*" } } },
      apply_properties = { ["node.description"] = "Speakers" },
    })

    table.insert(alsa_monitor.rules, {
      matches = { { { "node.name", "matches", "alsa_output.usb-AudioQuest_AudioQuest_DragonFly_Red*" } } },
      apply_properties = { ["node.description"] = "DAC" },
    })
  '';
}
