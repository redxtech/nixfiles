{ pkgs, config, lib, ... }: {
  console = {
    useXkbConfig = true;
    earlySetup = lib.mkDefault false;
  };

  boot = {
    plymouth = {
      enable = true;
      theme = "colorful_loop";
      themePackages = with pkgs; [ adi1090x-plymouth-themes ];
    };
    loader.timeout = lib.mkDefault 0;
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
