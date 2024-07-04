{ config, pkgs, lib, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "${pkgs.hyprlock}/bin/hyprlock";
          unlock_cmd = "${pkgs.procps}/bin/pkill -USR1 hyprlock}";
        };
        listener = [
          {
            timeout = cfg.wm.autolock.timeout;
            on-timeout = cfg.wm.scripts.wm.lock;
          }
          {
            timeout = 2 * cfg.wm.autolock.timeout;
            on-timeout = cfg.wm.scripts.wm.sleep;
          }
        ];
      };
    };
  };
}
