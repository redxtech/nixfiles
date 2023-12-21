{ config, pkgs, lib, ... }:

with lib;

{
  # This is required by podman to run containers in rootless mode.
  security.unprivilegedUsernsClone =
    mkDefault config.virtualisation.containers.enable;

  # enable polkit
  security.polkit.enable = true;

  # security.apparmor.enable = mkDefault true;
  # security.apparmor.killUnconfinedConfinables = mkDefault true;

  # enable antivirus clamav and
  # keep the signatures' database updated
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

}
