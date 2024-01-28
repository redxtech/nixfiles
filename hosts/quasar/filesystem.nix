{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7ed137e8-9837-49e9-95a0-fbd56358995f";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/39F1-D337";
      fsType = "vfat";
    };
  };

  swapDevices = [ ];
}
