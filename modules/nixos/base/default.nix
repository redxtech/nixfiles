{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkDefault mkOption mkEnableOption;
  inherit (config.networking) hostName;
  cfg = config.base;
  # only enable auto upgrade if current config came from a clean tree
  # this avoids accidental auto-upgrades when working locally.
  isClean = inputs.self ? rev;
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

    autoupdate = mkOption {
      type = bool;
      default = true;
      description = "Enable automatic updates.";
    };
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostname;

    time.timeZone = mkDefault cfg.tz;

    # defaults
    networking.networkmanager.enable = mkDefault true;

    # auto upgrade if enabled
    system.autoUpgrade = kmIf cfg.autoupdate {
      enable = isClean;
      dates = "hourly";
      flags = [ "--refresh" ];
      flake = "github:redxtech/nixfiles#${hostName}";
    };

    # Only run if current config (self) is older than the new one.
    systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
      serviceConfig.ExecCondition = lib.getExe
        (pkgs.writeShellScriptBin "check-date" ''
          lastModified() {
            nix flake metadata "$1" --refresh --json | ${
              lib.getExe pkgs.jq
            } '.lastModified'
          }
          test "$(lastModified "${config.system.autoUpgrade.flake}")"  -gt "$(lastModified "self")"
        '');
    };
  };
}
