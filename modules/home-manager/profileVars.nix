{ lib, config, ... }:

let cfg = config.profileVars;
in with lib; {
  options.profileVars = {
    enable = mkEnableOption "Whether to enable profile variables";

    isNixOS = mkOption {
      default = true;
      type = types.boolean;
      description = "Whether the system is NixOS.";
    };

    primaryMonitor = mkOption {
      default = "";
      type = types.str;
      description = "The primary monitor's name.";
    };

    network = {
      type = mkOption {
        default = "wired";
        type = types.str;
        description = "The type of network interface to use.";
      };

      interface = mkOption {
        default = "enp39s0";
        type = types.str;
        description = "The network interface to use.";
      };
    };

    backlightCard = mkOption {
      default = "intel_backlight";
      type = types.str;
      description = "The name of the backlight card.";
    };

    battery = {
      device = mkOption {
        default = "BAT0";
        type = types.str;
        description = "The name of the battery device.";
      };
      adapter = mkOption {
        default = "AC";
        type = types.str;
        description = "The name of the power adapter.";
      };
      full-at = mkOption {
        default = 98;
        type = types.int;
        description = "The percentage at which the battery is considered full.";
      };
    };

    hwmonPath = mkOption {
      default = "";
      type = types.str;
      description = "The path to the hwmon file.";
    };

    polybarModulesRight = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = "The modules to display on the right side of the polybar.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.polybar.settings = {

      "module/network".interface-type = mkDefault cfg.network.type;
      "module/temperature".hwmon-path = mkDefault cfg.hwmonPath;
      "module/backlight".card = mkDefault cfg.backlightCard;
      "module/battery" = {
        battery = mkDefault cfg.battery.device;
        adapter = mkDefault cfg.battery.adapter;
        full-at = mkDefault cfg.battery.full-at;
      };
    };
  };
}
