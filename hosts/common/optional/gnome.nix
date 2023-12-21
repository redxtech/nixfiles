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

      # extensions
      appindicator
      blur-my-shell
      caffeine
      clipboard-indicator
      docker
      focus-changer
      forge
      gesture-improvements
      grand-theft-focus
      just-perfection
      no-titlebar-when-maximized
      openweather
      pip-on-top
      power-profile-switcher
      switch-focus-type
      # system76-scheduler
      workspace-indicator-2
      vitals
      x11-gestures
    ];
}
