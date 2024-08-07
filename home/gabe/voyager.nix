{ config, lib, ... }:

{
  imports = [ ./sops.nix ./shared.nix ];

  base.enable = true;
  desktop = {
    wm = {
      enable = true;
      wm = "bspwm";
      bspwm.enable = true;
    };

    isLaptop = true;

    hardware = {
      cpuTempPath = "/sys/devices/platform/coretemp.0/hwmon/hwmon6/temp1_input";

      network = {
        type = "wireless";
        interface = "wlp59s0";
      };
    };

    monitors = [{
      name = "eDP-1";
      primary = true;
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
      fingerprint =
        "00ffffffffffff004d10ba1400000000161d0104a52213780ede50a3544c99260f505400000001010101010101010101010101010101ac3780a070383e403020350058c210000018000000000000000000000000000000000000000000fe004d57503154804c513135364d31000000000002410332001200000a010a202000d3";
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
