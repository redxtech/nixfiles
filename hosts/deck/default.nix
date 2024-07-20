{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "deck";

    clamav.enable = false;
    yubiauth.enable = false;

    # gpu = {
    #   enable = true;
    #   amd.enable = true;
    # };
  };

  desktop = {
    enable = true;
    wm = "gnome";
  };

  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "gnome";
      user = "gabe";
    };

    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
    };

    hardware.has.amd.gpu = true;

    decky-loader = {
      enable = true;
      # extraPackages = [ ];
    };
  };

  # environment.systemPackages = with pkgs; [ ];

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "gabe";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  programs.xwayland.enable = true;

  # backup = {
  #   rsync = {
  #     enable = true;
  #     paths = [ "/config" ];
  #     destination = "rsync:/backups/${config.networking.hostName}";
  #   };
  # };

  sops.secrets.cachix-agent = {
    path = "/etc/cachix-agent.token";
    sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "24.05";
}
