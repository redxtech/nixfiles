{ inputs, pkgs, lib, config, ... }:

{
  imports = [ ./global ./laptop.nix ./features/desktop/bspwm ];

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
  desktop.audio.devices = [{
    name = "Speakers";
    matches = "alsa_output.pci-0000_00_1f.3.*";
  }];
}
