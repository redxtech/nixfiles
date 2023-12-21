{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
  };
}
