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
    ../common/optional/cockpit.nix
    ../common/optional/containers.nix
    ../common/optional/desktop-apps.nix
    ../common/optional/gnome.nix
    ../common/optional/extra.nix
    ../common/optional/fail2ban.nix
    # ../common/optional/flatpak.nix
    ../common/optional/fonts.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    # ../common/optional/rdp.nix
    ../common/optional/security.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/theme.nix
    ../common/optional/virtualization.nix
    ../common/optional/zfs.nix
  ];

  networking.hostName = "quasar";

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
