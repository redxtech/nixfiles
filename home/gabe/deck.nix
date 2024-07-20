{ config, pkgs, ... }:

{
  imports = [ ./sops.nix ];

  base.enable = true;
  cli.enable = true;
  desktop = {
    enable = true;

    enableMonitors = false;
    isLaptop = true;

    hardware = {
      cpuTempPath =
        "/sys/devices/virtual/thermal/thermal_zone0/hwmon4/temp1_input";
      network = {
        type = "wireless";
        interface = "wlo1";
      };
    };

    audio.devices = [
      # {
      #   name = "Speakers";
      #   matches = "alsa_output.pci-0000_2e_00*";
      # }
      {
        name = "Ultras";
        type = "bluetooth";
        matches = "bluez_output.BC_87_FA_26_3B_97.*";
      }
    ];
  };

  # enable some things
  services.syncthing.enable = true;

  # disable some things
  desktop.spicetify.enable = false;
  programs.firefox.useCustomCss = false;
  programs.neovim.neo-lsp.enable = false;

  home.packages = with pkgs; [ moonlight-qt ];
}
