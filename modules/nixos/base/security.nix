{ pkgs, lib, config, ... }:

let
  cfg = config.base;
  inherit (lib) mkIf mkDefault;
in {
  # options.base = { };

  config = let
  in mkIf cfg.enable {
    # enable polkit
    security.polkit.enable = true;
    # security.apparmor.enable = mkDefault true;
    # security.apparmor.killUnconfinedConfinables = mkDefault true;

    # enable antivirus clamav and
    services.clamav.daemon.enable = true;
    services.clamav.updater.enable = true;

    # pwless sudo
    security.sudo = {
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
          ++ (mkNoPwd pkgs.ps_mem "ps_mem");
        groups = [ "wheel" ];
      }];
    };

    # increase open file limit for sudoers
    security.pam.loginLimits = mkDefault [
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
}
