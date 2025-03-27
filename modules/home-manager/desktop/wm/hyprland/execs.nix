{ config, pkgs, lib, ... }:

let
  inherit (config.desktop.autostart) desktop services run processed;
  inherit (builtins) map;
  cfg = config.desktop.wm.hyprland;

  mkUnit = cmd: type: "${pkgs.app2unit}/bin/app2unit -s ${type} -- ${cmd}";
  mkDesktop = cmd: mkUnit cmd "a";
  mkService = cmd: mkUnit cmd "b";

  runDesktop = map mkDesktop desktop;
  runService = map mkService services;

  runBG = (map (cmd: "${cmd} &") run);
in {
  wayland.windowManager.hyprland = lib.mkIf cfg.enable {
    settings.exec = runDesktop ++ runService ++ runBG ++ processed;
  };
}
