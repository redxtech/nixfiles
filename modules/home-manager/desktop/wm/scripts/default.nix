{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.desktop;

  general = (import ./general) { inherit pkgs lib; };
  rofi = (import ./rofi) { inherit pkgs lib config; };
in
{
  options.desktop.wm.scripts =
    let
      inherit (lib) mkOption types;

      scriptOpt =
        script: name:
        mkOption {
          type = types.str;
          default = script;
          description = name;
        };
    in
    {
      general = {
        clipboard = scriptOpt "${general.clipboard}/bin/clipboard" "Clipboard history script";
        copy-spotify-url = scriptOpt "${general.copy-spotify-url}/bin/copy-spotify-url" "Copy the current Spotify URL";
        ha = scriptOpt "${general.ha}/bin/home-assistant" "Home Assistant script";
        hdrop-btop = scriptOpt "${general.hdrop-btop}/bin/hdrop-btop" "Toggle btop dropdown";
        ps_mem = scriptOpt "${general.ps_mem}/bin/ps_mem_float" "Open ps_mem terminal";
        unarchiver = scriptOpt "${general.unarchiver}/bin/unarchiver" "Unarchiver script";
        wttr = scriptOpt "${general.wttr}/bin/wttr" "Open wttr.in terminal";
      };

      rofi = {
        app-launcher = scriptOpt "${pkgs.fuzzel}/bin/fuzzel" "The application launcher to use";
        app-launcher-alt = scriptOpt "${config.services.vicinae.package}/bin/vicinae" "The application launcher to use";
        archiver = scriptOpt "${rofi.archiver}/bin/archiver" "Archive script";
        choose-wallpaper = scriptOpt "${rofi.choose-wallpaper}/bin/choose-wallpaper" "Choose a wallpaper";
        convert = scriptOpt "${rofi.convert}/bin/convert-image" "Image conversion script";
        encoder = scriptOpt "${rofi.encoder}/bin/encoder" "Video encoder script";
        nerd-icons = scriptOpt "${rofi.nerd-icons}/bin/nerd-icons" "Nerd Icon chooser";
        youtube = scriptOpt "${rofi.youtube}/bin/youtube" "YouTube watch/download script";
      };

      wm = {
        lock = scriptOpt "${pkgs.hyprlock}/bin/hyprlock" "Run the screenlocker";
        powermenu = scriptOpt "${rofi.powermenu}/bin/powermenu" "The power menu to use";
        sleep = scriptOpt "${pkgs.coreutils}/bin/sleep 0.5 && ${pkgs.hyprland}/bin/hyprctl dispatch dpms off" "Sleep the screen";
        wallpaper = scriptOpt "${pkgs.swww}/bin/swww img" "Set the wallpaper";
      };
    };

  config = lib.mkIf cfg.enable {
    home.packages = [
      general.ha
      general.hdrop-btop
      general.ps_mem
      rofi.archiver
      rofi.choose-wallpaper
      rofi.convert
      rofi.encoder
      rofi.nerd-icons
      rofi.powermenu
      rofi.search-icons
      rofi.youtube
    ];
  };
}
