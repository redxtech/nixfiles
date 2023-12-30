{ inputs, outputs, pkgs, ... }:

{
  imports = [
    ./global
    ./features/desktop/bspwm
    ./features/desktop/common/kdeconnect.nix
  ];

  colorscheme = inputs.nix-colors.colorschemes.dracula;
  # wallpaper = outputs.wallpapers.aenami-all-i-need;

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
