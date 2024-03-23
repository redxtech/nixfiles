{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption mkDefault;
  cfg = config.desktop;
in {
  imports = [
    # submodules
    ./apps
    ./audio.nix
    ./autostart.nix
    ./monitors.nix
    ./wm
  ];

  options.desktop = with lib.types; {
    enable = lib.mkEnableOption "Enable desktop configuration";

    isLaptop = mkOption {
      type = bool;
      default = false;
      description = ''
        Whether the system is a laptop.
      '';
      example = true;
    };

    hardware = {
      battery = {
        hasBattery = mkOption {
          type = bool;
          default = false;
          description = ''
            Whether the system has a battery.
          '';
          example = true;
        };

        device = mkOption {
          type = str;
          default = "BAT0";
          description = "The name of the battery device.";
        };

        adapter = mkOption {
          type = str;
          default = "AC";
          description = "The name of the power adapter.";
        };

        full-at = mkOption {
          type = int;
          default = 98;
          description =
            "The percentage at which the battery is considered full.";
        };
      };

      cpuTempPath = mkOption {
        type = str;
        default = null;
        description = ''
          The path to the file containing the CPU temperature.
        '';
        example = "/sys/class/thermal/thermal_zone0/temp";
      };

      backlightCard = mkOption {
        type = str;
        default = "intel_backlight";
        description = "The name of the backlight card.";
      };

      network = {
        interface = mkOption {
          type = str;
          default = null;
          example = "enp39s0";
          description = ''
            The network interface to use for the audio server.
            If null, the default interface will be used.
          '';
        };

        type = mkOption {
          type = enum [ "wired" "wireless" ];
          default = null;
          description = ''
            The type of network interface.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    desktop.hardware.battery.hasBattery = mkDefault cfg.isLaptop;
  };
}
