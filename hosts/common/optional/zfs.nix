{ pkgs, lib, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoSnapshot.enable = true;
    autoScrub.enable = true;
    # trim.enable = true;
  };
}
