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
      hasBattery = mkOption {
        type = bool;
        default = false;
        description = ''
          Whether the system has a battery.
        '';
        example = true;
      };

      cpuTempPath = mkOption {
        type = str;
        default = null;
        description = ''
          The path to the file containing the CPU temperature.
        '';
        example = "/sys/class/thermal/thermal_zone0/temp";
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

  config =
    mkIf cfg.enable { desktop.hardware.hasBattery = mkDefault cfg.isLaptop; };
}
