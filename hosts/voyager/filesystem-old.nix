{ config, lib, pkgs, modulesPath, ... }:

{
  boot = {
    loader.efi.efiSysMountPoint = "/boot/efi";

    initrd = {
      systemd.enable = true;

      # setup keyfile
      secrets = { "/crypto_keyfile.bin" = null; };
      # enable swap on luks
      luks.devices = {
        "luks-56051129-eb6d-4e41-b9e3-f4a6f2a35d0a" = {
          device = "/dev/disk/by-uuid/56051129-eb6d-4e41-b9e3-f4a6f2a35d0a";
          keyFile = "/crypto_keyfile.bin";
        };
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6266c14d-0c06-4fe1-ac9f-49eaf2310252";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-24fe8a73-27ce-431b-a16d-ca5dccadcd5c".device =
    "/dev/disk/by-uuid/24fe8a73-27ce-431b-a16d-ca5dccadcd5c";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/EF04-7245";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/6bd41642-5a8c-4292-be4b-c7b74b4d44ac"; }];
}
