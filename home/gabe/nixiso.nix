{ inputs, pkgs, lib, config, ... }:

{
  imports = [ ./global ./features/desktop/bspwm ];

  # TODO:
  # - improve modularity to allow removal of more features from nixiso
  # - set default values for things that use profileVars

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
}
