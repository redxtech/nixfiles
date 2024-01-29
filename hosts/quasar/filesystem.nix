{ pkgs, lib, ... }:

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

    # btrfs mirrored config volumes
    "/config" = {
      device = "/dev/disk/by-uuid/2fb799ea-69bf-476a-912a-ec7986f80a6f";
      fsType = "btrfs";
      options = [ "compress=zstd" ];
    };

    # zfs pools
    "/pool" = mkZfs "pool";
    "/pool/cloud" = mkZfs "pool/cloud";
    "/pool/data" = mkZfs "pool/data";
    "/pool/downloads" = mkZfs "pool/downloads";
    "/pool/media" = mkZfs "pool/media";
    "/pool/settings" = mkZfs "pool/settings";

    # temp disabled
    # "/lake" = mkZfs "lake";
  };

  # needed for zfs
  networking.hostId = "74996f49";

  swapDevices = [ ];

  boot.supportedFilesystems = [ "btrfs" ];
  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
