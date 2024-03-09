{ inputs, pkgs, lib, config, ... }:

{
  imports = [ ./shared.nix ];

  desktop = {
    wm.wm = "bspwm";

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
  };

  # temp additional profiles for laptop
  programs.autorandr.profiles = {
    laptop-dual = {
      config = {
        "eDP-1" = {
          mode = "1920x1080";
          rate = "60.00";
          position = "0x0";
          primary = true;
        };
        "DP-1" = {
          mode = "1920x1200";
          # rate = "60.00";
          rate = "59.88";
          position = "1920x0";
          primary = false;
        };
      };
      fingerprint = {
        "eDP-1" =
          "00ffffffffffff004d10ba1400000000161d0104a52213780ede50a3544c99260f505400000001010101010101010101010101010101ac3780a070383e403020350058c210000018000000000000000000000000000000000000000000fe004d57503154804c513135364d31000000000002410332001200000a010a202000d3";
        "DP-1" =
          "00ffffffffffff00066d33bc0201010123200104b52413782f57a1b33333cc14145054210800d100b3009500810001010101010101019c6800a0a04029603020350068be1000001a3ad100a0a04029603020350068be1000001a000000fc0041534d2d3136305143430a2020000000fd0030a5c8c83c010a202020202020015902032ef2459001020304e200d523097f0783010000e305c000e60605016262006dd85dc4018200000000000000006a5e00a0a0a029503020350068be1000001eaae200a0a04029603020350068be1000001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064";
      };
    };
    laptop-dual-secondary = {
      config = {
        "eDP-1" = {
          mode = "1920x1080";
          rate = "60.00";
          position = "0x0";
          primary = false;
        };
        "DP-1" = {
          mode = "1920x1200";
          rate = "60.00";
          position = "1920x0";
          primary = true;
        };
      };
      fingerprint = {
        "eDP-1" =
          "00ffffffffffff004d10ba1400000000161d0104a52213780ede50a3544c99260f505400000001010101010101010101010101010101ac3780a070383e403020350058c210000018000000000000000000000000000000000000000000fe004d57503154804c513135364d31000000000002410332001200000a010a202000d3";
        "DP-1" =
          "00ffffffffffff0010ac67404c524d331415010380331d78ea0cb4a257519f270a5054a54b00714f8180d1c001010101010101010101023a801871382d40582c4500fd1e1100001e000000ff004b4b4a4d54313545334d524c0a000000fc0044454c4c205032333131480a20000000fd00384c1e5311000a202020202020017802030e01411067030c001000003c023a801871382d40582c45006d552100001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025";
      };
    };
  };
}
