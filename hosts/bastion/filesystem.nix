{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-uuid/f8fd6528-3acf-4826-9707-94e421cd105f";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "4096M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs =
                  [ "-f" "--nodesize" "8192" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/rootfs" = { mountpoint = "/"; };
                  # Subvolume name is the same as the mountpoint
                  "/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  # Sub(sub)volume doesn't need a mountpoint as its parent is mounted
                  "/home/gabe" = { };
                  # Parent is not mounted so the mountpoint must be set
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  # Subvolume for the swapfile
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "20M";
                      swapfile2.size = "20M";
                      swapfile2.path = "rel-path";
                    };
                  };
                };

                mountpoint = "/partition-root";
                swap = {
                  swapfile = { size = "20M"; };
                  swapfile1 = { size = "20M"; };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems = {
    "/media/big-goober" = {
      device = "/dev/disk/by-uuid/bdfecef7-9904-49df-8c0d-dd14d0e60810";
      fsType = "btrfs";
      options = [ "rw" "lazytime" "space_cache" "subvolid=5" "subvol=/" ];
      mountPoint = "/media/big-goober";
    };

    "/media/mid-goober" = {
      device = "/dev/disk/by-uuid/7fbace0e-0bba-4ec5-9c5c-05105ffefb6d";
      fsType = "btrfs";
      options = [ "rw" "lazytime" "space_cache" "subvolid=5" "subvol=/" ];
      mountPoint = "/media/mid-goober";
    };
  };
}
