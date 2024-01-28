{ lib, ... }:

{
  fileSystems = let
    mkZfs = name: {
      device = name;
      fsType = "zfs";
    };
  in {
    "/" = {
      device = "/dev/disk/by-uuid/7ed137e8-9837-49e9-95a0-fbd56358995f";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/39F1-D337";
      fsType = "vfat";
    };

    # zfs mounts
    "/pool" = mkZfs "pool";
    "/pool/downloads" = mkZfs "pool/downloads";
    "/pool/data" = mkZfs "pool/data";
    "/pool/settings" = mkZfs "pool/settings";
    "/pool/media" = mkZfs "pool/media";
    "/pool/cloud" = mkZfs "pool/cloud";

    "/lake" = mkZfs "lake";
  };

  boot.zfs.extraPools = [ "pool" "lake" ];

  # needed for zfs
  networking.hostId = "74996f49";

  swapDevices = [ ];
}
