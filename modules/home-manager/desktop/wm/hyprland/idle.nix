{ config, pkgs, lib, ... }:

let cfg = config.desktop.wm;
in {
  config = lib.mkIf cfg.hyprland.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "${pkgs.hyprlock}/bin/hyprlock";
          unlock_cmd = "${pkgs.procps}/bin/pkill -USR1 hyprlock";
        };
        listener = [
          {
            timeout = cfg.autolock.timeout;
            on-timeout = cfg.scripts.wm.lock;
          }
          {
            timeout = 2 * cfg.autolock.timeout;
            on-timeout = cfg.scripts.wm.sleep;
          }
          (lib.mkIf config.desktop.isLaptop {
            timeout = 3 * cfg.autolock.timeout;
            on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
          })
        ];
      };
    };
  };
}
