{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    ./filesystem.nix

    ./services
    ./acme.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe

    ../common/optional/btrfs.nix
    ../common/optional/gnome.nix
    # ../common/optional/rdp.nix
    ../common/optional/zfs.nix
  ];

  networking.hostName = "quasar";

  base = {
    enable = true;
    hostname = "quasar";
    tz = "America/Vancouver";
  };

  desktop = {
    enable = true;
    useZen = false;
  };

  nas = {
    enable = true;
    domain = "nas.gabedunn.dev";
    paths.config = "/config/pods";
  };

  backup = {
    rsync = {
      enable = true;
      paths = [ "/config" ];
      destination = "rsync:/backups/${config.networking.hostName}";
    };
  };

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware = { opengl.enable = true; };

  # dbus packages
  services.dbus.packages = with pkgs; [ python310Packages.dbus-python ];

  # ensure gnome settings daemon is running
  services.udev = { packages = with pkgs; [ gnome.gnome-settings-daemon ]; };

  system.stateVersion = "23.11";
}
