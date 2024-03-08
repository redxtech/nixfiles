{ inputs, outputs, pkgs, lib, config, ... }:

{
  imports = [
    ./global
    ./desktop.nix
    ./features/desktop/bspwm
    # ./features/desktop/hyprland
    ./features/desktop/common/kdeconnect.nix
  ];

  colorscheme = inputs.nix-colors.colorschemes.dracula;

  profileVars = {
    enable = true;

    primaryMonitor = "DisplayPort-0";
    secondaryMonitor = "DisplayPort-1";

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

  services.polybar = with lib; {
    script = ''
      polybar main &
      polybar secondary &
    '';

    settings = {
      "bar/secondary" = {
        inherit (config.services.polybar.settings."bar/main")
          width height line-size offset bottom fixed-center wm-restack
          override-redirect enable-ipc background foreground cursor font;

        monitor = "${config.profileVars.secondaryMonitor}";

        modules = {
          left = concatStringsSep " " [ "bspwm" "margin" "polywins-secondary" ];
          center = config.services.polybar.settings."bar/main".modules.center;
          right = concatStringsSep " " (config.profileVars.polybarModulesRight
            ++ [ "margin" "powermenu" ]);
        };
      };
      "module/polywins-secondary" = let
        scripts = (import ./features/desktop/bspwm/polybar/scripts) {
          inherit pkgs lib;
        };
      in {
        inherit (config.services.polybar.settings."module/polywins")
          format label tail type;

        exec =
          "${scripts.polywins}/bin/polywins ${config.profileVars.secondaryMonitor}";
      };
    };
  };

  services.syncthing.enable = true;

  desktop.audio.devices = [
    {
      name = "Schiit Stack";
      matches = "alsa_output.usb-Schiit_Audio_Schiit_Unison_Modi_Multi_2-00.*";
    }
    {
      name = "Speakers";
      matches = "alsa_output.pci-0000_2e_00*";
    }
    {
      name = "Arctis 7 Game";
      matches =
        "alsa_output.usb-SteelSeries_SteelSeries_Arctis_7-00*stereo-game*";
    }
    {
      name = "Arctis 7 Chat";
      matches =
        "alsa_output.usb-SteelSeries_SteelSeries_Arctis_7-00*mono-chat*";
    }
  ];
}
