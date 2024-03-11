{ pkgs, lib, config, ... }:

let
  cfg = config.base;
  inherit (lib) mkIf mkDefault mkOption mkEnableOption;
in {
  options.base = with lib.types; {
    enable = mkEnableOption "Enable the base system module.";
    hostname = mkOption {
      type = str;
      default = "nixos";
      description = "The hostname of the machine.";
    };

    tz = mkOption {
      type = str;
      default = "America/Vancouver";
      description = "The timezone of the machine.";
    };
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostname;

    time.timeZone = mkDefault cfg.tz;

    # defaults
    networking.networkmanager.enable = mkDefault true;
  };
}
