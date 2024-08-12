{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    # device = "/dev/disk/by-uuid/xxx";
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
            mountpoint = "/partition-root";
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
            };
          };
        };
        swap = {
          size = "38G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true; # resume from hiberation from this device
          };
        };
      };
    };
  };
}
