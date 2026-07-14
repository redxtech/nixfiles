{ lib, ... }:

{
  den.aspects.boot.nixos =
    { host, pkgs, ... }:
    let
      cfg = host.settings.base;
    in
    {
      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            configurationLimit = lib.mkDefault 5;
            consoleMode = "max";
          };
          timeout = lib.mkDefault 1;
          efi.canTouchEfiVariables = true;
        };

        initrd = {
          verbose = false;
          systemd.enable = true;
        };

        plymouth = {
          enable = true;
          # TODO: make theme take colours from stylix??
          theme = lib.mkForce "colorful_loop";
          themePackages = with pkgs; [ adi1090x-plymouth-themes ];
        };

        tmp.useTmpfs = true;

        kernelParams = [
          "quiet"
          "loglevel=3"
          "systemd.show_status=auto"
          "udev.log_level=3"
          "rd.udev.log_level=3"
          "vt.global_cursor_default=0"
        ];

        # TODO: look into binfmt

        # TODO: maybe pull from parsed filesystems?
        supportedFilesystems = {
          inherit (cfg.fs) btrfs zfs;
        };

        zfs.forceImportRoot = false;
        consoleLogLevel = 0;
      };

      console.useXkbConfig = true;
    };
}
