{ lib, ... }:

let enableDisko = false;
in {
  config = {
    disko.devices = lib.mkIf enableDisko {
      disk = {
        main = {
          device = "/dev/disk/by-id/some-disk-id";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
