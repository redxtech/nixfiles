{ pkgs, lib, ... }:

{
  # boot.zfs = {
  #   enabled = true;
  #   extraPools = [ "pool" ];
  #   # allowHibernation = true;
  # };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "74996f49";

  services.zfs = {
    autoSnapshot.enable = true;
    autoScrub.enable = true;
    # trim.enable = true;
  };
}
