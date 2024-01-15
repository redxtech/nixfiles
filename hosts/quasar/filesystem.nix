{
  # disko.devices = {
  #   disk = {
  #     main = {
  #       type = "disk";
  #       device = "/dev/nvme1n1";
  #     };
  #   };
  # };

  fileSystems = {

    "/" = {
      device = "/dev/disk/by-uuid/23897c98-40ef-468e-91ca-57d303aa9869";
      fsType = "xfs";
    };

    "/home" = {
      device = "/dev/disk/by-uuid/634c0c14-052b-4d52-964b-3ae11159583d";
      fsType = "xfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/1280b2f3-3907-4127-bf43-c1434155648a";
      fsType = "xfs";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/B41C-7411";
      fsType = "vfat";
    };

    "/pool" = {
      device = "pool";
      fsType = "zfs";
    };

    "/pool/downloads" = {
      device = "pool/downloads";
      fsType = "zfs";
    };

    "/pool/data" = {
      device = "pool/data";
      fsType = "zfs";
    };

    "/pool/settings" = {
      device = "pool/settings";
      fsType = "zfs";
    };

    "/pool/photos" = {
      device = "pool/photos";
      fsType = "zfs";
    };

    "/pool/games" = {
      device = "pool/games";
      fsType = "zfs";
    };

    "/pool/media" = {
      device = "pool/media";
      fsType = "zfs";
    };

    "/pool/cloud" = {
      device = "pool/cloud";
      fsType = "zfs";
    };

    "/var/lib/containers/storage/overlay" = {
      device = "/var/lib/containers/storage/overlay";
      fsType = "none";
      options = [ "bind" ];
    };
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/1821f890-c566-4b72-a467-e92dd275b9ee"; }];
}
