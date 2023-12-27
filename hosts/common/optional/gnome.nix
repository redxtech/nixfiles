{ config, pkgs, ... }:

{
  services = {
    xserver = {
      desktopManager.gnome = { enable = true; };
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
    geoclue2.enable = true;
    gnome.games.enable = true;
  };
  # Fix broken stuff
  services.avahi.enable = false;
  networking.networkmanager.enable = false;

  environment.systemPackages = with pkgs;
    with gnome;
    with gnomeExtensions; [
      gpaste
      gnome3.gnome-tweaks

      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.docker
      gnomeExtensions.focus-changer
      gnomeExtensions.forge
      gnomeExtensions.gesture-improvements
      gnomeExtensions.grand-theft-focus
      gnomeExtensions.just-perfection
      gnomeExtensions.no-titlebar-when-maximized
      gnomeExtensions.openweather
      gnomeExtensions.pip-on-top
      gnomeExtensions.power-profile-switcher
      gnomeExtensions.switch-focus-type
      # gnomeExtensions.system76-scheduler
      gnomeExtensions.workspace-indicator-2
      gnomeExtensions.vitals
      gnomeExtensions.x11-gestures
    ];
}
