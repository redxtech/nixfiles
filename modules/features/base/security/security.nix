{ den, lib, ... }:

{
  den.aspects.security = {
    includes = [
      den.aspects.av
      den.aspects.acme
      den.aspects.yubikey
    ];

    nixos = { host, pkgs, ... }: {
      security.polkit.enable = true;

      security.sudo = {
        enable = true;

        # disable password on headless systems
        wheelNeedsPassword = host.settings.base.hasDisplay;

        # pwless sudo for certain commands
        extraRules =
          let
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
          in
          [
            {
              commands =
                (mkNoPwd pkgs.unixtools.fdisk "fdisk -l")
                ++ (mkNoPwd pkgs.ps_mem "ps_mem")
                ++ (mkNoPwd pkgs.systemd "systemctl restart xremap.service");
              groups = [ "wheel" ];
            }
          ];
      };

      # increase open file limit for sudoers
      security.pam.loginLimits = lib.mkDefault [
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

      # security.apparmor.enable = mkDefault true;
      # security.apparmor.killUnconfinedConfinables = mkDefault true;
    };
  };
}
