{ config, lib, pkgs, ... }:

let
  cfg = config.base;
  inherit (lib) mkEnableOption mkIf mkDefault;
in {
  options.base = {
    clamav = {
      enable = mkEnableOption "Enable ClamAV antivirus" // { default = true; };
      fangfrisch = mkEnableOption "Enable fangfrisch" // { default = true; };
    };
  };

  config = mkIf cfg.enable {
    # install gui apps if desktop is enabled
    environment.systemPackages = with pkgs;
      mkIf config.desktop.enable [ clamtk ];

    # security.apparmor.enable = mkDefault true;
    # security.apparmor.killUnconfinedConfinables = mkDefault true;

    # enable antivirus clamav
    services.clamav = mkIf config.base.clamav.enable {
      package = pkgs.clamav;
      daemon.enable = true;
      scanner.enable = true;
      updater.enable = true;
      fangfrisch.enable = cfg.clamav.fangfrisch;
    };

    security = {
      # enable polkit
      polkit.enable = true;

      # pwless sudo
      sudo = {
        enable = true;

        extraRules = let
          mkRule = pkg: cmd: rules: [
            {
              command = "${pkg}/bin/${cmd}";
              options = rules;
            }
            {
              command = "/run/current-system/sw/bin/${cmd}";
              options = rules;
            }
          ];
          mkNoPwd = pkg: cmd: mkRule pkg cmd [ "NOPASSWD" ];
        in [{
          commands = (mkNoPwd pkgs.unixtools.fdisk "fdisk -l")
            ++ (mkNoPwd pkgs.ps_mem "ps_mem")
            ++ (mkNoPwd pkgs.systemd "systemctl restart xremap.service");
          groups = [ "wheel" ];
        }];
      };

      # increase open file limit for sudoers
      pam.loginLimits = mkDefault [
        {
          domain = "@wheel";
          item = "nofile";
          type = "soft";
          value = "524288";
        }
        {
          domain = "@wheel";
          item = "nofile";
          type = "hard";
          value = "1048576";
        }
      ];
    };
  };
}
