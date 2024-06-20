{ config, pkgs, lib, ... }:

let
  cfg = config.desktop.wm;

  bar = (import ./bar) { inherit pkgs lib; };
  general = (import ./general) { inherit pkgs lib; };
  launchers = (import ./launchers) { inherit pkgs lib config; };
in {
  options.desktop.wm.scripts = let
    inherit (lib) mkOption types;

    scriptOpt = script: name:
      mkOption {
        type = types.str;
        default = script;
        description = name;
      };
  in {
    bar = with bar; {
      pipewire = scriptOpt "${pipewire}/bin/pipewire" "Pipewire control script";
      playerctl-tail = scriptOpt "${playerctl-tail}/bin/playerctl-tail"
        "Playerctl tail script";
      spotify-volume = scriptOpt "${spotify-volume}/bin/spotify-volume"
        "Script to control Spotify volume";
      weather = scriptOpt "${weather}/bin/weather-bar" "Weather script";
    };

    launchers = with launchers; {
      app-launcher =
        scriptOpt "${pkgs.fuzzel}/bin/fuzzel" "The application launcher to use";
      powermenu =
        scriptOpt "${powermenu}/bin/powermenu" "The power menu to use";
    };

    general = {
      clipboard = scriptOpt "${general.clipboard}/bin/clipboard"
        "Clipboard history script";
      copy-spotify-url =
        scriptOpt "${general.copy-spotify-url}/bin/copy-spotify-url"
        "Copy the current Spotify URL";
      ha = scriptOpt "${general.ha}/bin/home-assistant" "Home Assistant script";
      hdrop-btop =
        scriptOpt "${general.hdrop-btop}/bin/hdrop-btop" "Toggle btop dropdown";
      ps_mem = scriptOpt "${general.ps_mem}/bin/ps_mem" "Open ps_mem terminal";
      wttr = scriptOpt "${general.wttr}/bin/wttr" "Open wttr.in terminal";
    };

    wm = {
      lock = scriptOpt "${pkgs.hyprlock}/bin/hyprlock" "Run the screenlocker";
      sleep = scriptOpt
        "${pkgs.coreutils}/bin/sleep 1 && ${pkgs.hyprland}/bin/hyprctl dispatch dpms off"
        "Sleep the screen";
      wallpaper = scriptOpt "${pkgs.swww}/bin/swww img" "Set the wallpaper";
    };
  };

  config = lib.mkIf cfg.enable { };
}
