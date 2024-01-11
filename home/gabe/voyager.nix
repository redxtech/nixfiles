{ inputs, outputs, pkgs, lib, config, ... }:

{
  imports = [ ./global ./features/desktop/bspwm ];

  #  ------
  # | eDP-1|
  #  ------
  monitors = [{
    name = "eDP-1";
    width = 1920;
    height = 1080;
    primary = true;
  }];

  colorscheme = inputs.nix-colors.colorSchemes.dracula;

  profileVars = {
    enable = true;

    primaryMonitor = "eDP-1";

    network = {
      type = "wireless";
      interface = "wlp59s0";
    };

    hwmonPath = "/sys/devices/platform/coretemp.0/hwmon/hwmon6/temp1_input";

    polybarModulesRight = [
      "margin"
      "weather"
      "margin"
      "backlight"
      "margin"
      # "kdeconnect"
      # "margin"
      "pipewire"
      "margin"
      "memory"
      "margin"
      "temperature"
      "margin"
      "cpu"
      "margin"
      "network"
      "margin"
      "battery"
      "margin"
      "date"
      "margin"
      "dnd"
    ];
  };

  # desktop layout
  xsession.windowManager.bspwm = {
    monitors = {
      "${config.profileVars.primaryMonitor}" =
        [ "shell" "www" "chat" "music" "files" "video" ];
    };
  };

  # laptop only polybar stuff
  services.polybar = {
    script = ''
      polybar main &
    '';

    settings = with builtins;
      with lib.strings; {
        "module/network" = { label.connected.text = "%essid%"; };
      };
  };

  # rename wireplumber devices
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
