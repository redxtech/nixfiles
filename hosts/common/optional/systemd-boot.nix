{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 2;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
  };
}
