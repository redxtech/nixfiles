{ inputs, outputs, pkgs, ... }:

{
  imports = [
    ./global
    ./features/desktop/bspwm
    ./features/desktop/common/kdeconnect.nix
  ];

  monitors = [
    {
      name = "DP-1";
      width = 2560;
      height = 1440;
      primary = true;
      rate = 144;
    }
    {
      name = "DP-2";
      width = 2560;
      height = 1440;
      x = 2560;
      rate = 144;
    }
  ];

  colorscheme = inputs.nix-colors.colorschemes.dracula;

  profileVars = {
    enable = true;

    primaryMonitor = "DP-1";

    network = {
      type = "wired";
      interface = "enp39s0";
    };

    hwmonPath = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon3/temp3_input";

    polybarModulesRight = [
      "weather"
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
      "date"
      "margin"
      "dnd"
    ];
  };

  xsession.windowManager.bspwm = {
    monitors = {
      "DP-1" = [ "shell" "www" "chat" "files" "five" "six" ];
      "DP-2" = [ "r-www" "music" "video" "ten" ];
    };

    startupPrograms =
      [ "${pkgs.bspwm}/bin/bspc wm --reorder-monitors DP-1 DP-2" ];
  };
}
