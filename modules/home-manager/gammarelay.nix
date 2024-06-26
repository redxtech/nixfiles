{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.services.gammarelay;
in {
  options.services.gammarelay = {
    enable = mkEnableOption "enable gammarelay";

    package = mkOption {
      type = types.package;
      default = pkgs.wl-gammarelay-rs;
      defaultText = lib.literalExpression "pkgs.wl-gammarelay-rs";
      description = "wl-gammarelay-rs derivation to use.";
    };

    args = mkOption {
      type = types.str;
      default = "{t}K {bp}%";
      example = "{t}K {bp}%";
      description = "Extra arguments to pass to gammarelay.";
    };
  };

  config = mkIf cfg.enable {
    # create a systemd service for gammarelay
    systemd.user.services.gammarelay = {
      Unit = {
        Description = "Gammarelay daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "simple";
        ExecStart = ''${cfg.package}/bin/wl-gammarelay-rs watch "${cfg.args}"'';
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
