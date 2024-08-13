{ config, lib, ... }:

{
  imports = [ ./sops.nix ./shared.nix ];

  base.enable = true;
  desktop = {
    wm = {
      enable = true;
      wm = "hyprland";
      hyprland.enable = true;
    };

    isLaptop = true;

    hardware = {
      cpuTempPath =
        "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon6/temp1_input";

      network = {
        type = "wireless";
        interface = "wlp4s0";
      };
    };

    monitors = [{
      name = "eDP-2";
      primary = true;
      height = 1600;
      width = 2560;
      rate = 165;
      workspaces = [
        {
          name = "shell";
          number = 1;
          icon = "";
        }
        {
          name = "www";
          number = 2;
          icon = "";
        }
        {
          name = "chat";
          number = 3;
          icon = "󰙯";
        }
        {
          name = "files";
          number = 4;
          icon = "󰉋";
        }
        {
          name = "five";
          number = 5;
        }
        {
          name = "six";
          number = 6;
        }
        {
          name = "seven";
          number = 7;
        }
        {
          name = "eight";
          number = 8;
        }
        {
          name = "nine";
          number = 9;
        }
        {
          name = "ten";
          number = 10;
        }
      ];
      fingerprint = "";
    }];

    # rename wireplumber devices
    audio.devices = [
      {
        name = "Speakers";
        matches = "alsa_output.pci-0000_00_1f.3.*";
      }
      {
        name = "Ultras";
        type = "bluetooth";
        matches = "bluez_output.BC_87_FA_26_3B_97.*";
      }
    ];
  };
}
