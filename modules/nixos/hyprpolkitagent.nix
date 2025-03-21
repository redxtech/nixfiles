{ config, lib, pkgs, ... }:

let cfg = config.programs.hyprland.polkitAgent;
in {
  options.programs.hyprland.polkitAgent = {
    enable = lib.mkEnableOption "Enable polkit agent for hyprland";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.hyprpolkitagent;
      defaultText = "pkgs.hyprpolkitagent";
      description = "Package to use for polkit agent";
    };
  };

  config = lib.mkIf config.programs.hyprland.polkitAgent.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user.services.hyprland-polkit-agent = {
      description = "Hyprland Polkit Authentication Agent";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/libexec/hyprpolkitagent";
        Slice = "session.slice";
        TimeoutStopSec = 5;
        Restart = "on-failure";
      };
    };
  };
}
