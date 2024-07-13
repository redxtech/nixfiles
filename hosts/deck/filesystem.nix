{ config, pkgs, lib, ... }:

{

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5ebc07cb-48a0-4cf4-b7d1-e0f4b6d8edd0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7871-198B";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
}
