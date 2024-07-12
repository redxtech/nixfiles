{ pkgs, lib, ... }:

{

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/21b496bf-a476-43fd-a24a-b79f6fcfda8a";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/BB20-581A";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
}
