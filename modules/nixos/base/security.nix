{ config, lib, pkgs, ... }:

let
  cfg = config.base;
  inherit (cfg) hostname domain;
  inherit (lib) mkEnableOption mkIf mkDefault;
in {
  options.base = {
    clamav = {
      enable = mkEnableOption "Enable ClamAV antivirus" // { default = true; };
      fangfrisch = mkEnableOption "Enable fangfrisch" // { default = true; };

      daily = mkEnableOption "Enable daily scans" // { default = true; };
    };

    acme.enable = mkEnableOption "Enable ACME cert gen" // { default = true; };
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
      daemon.settings.ExcludePath = [
        "^/dev"
        "^/proc"
        "^/sys"
        "^/run"
        "^/var/"
        "^/nix/store/"
        "^/pool/media/"
        "^/home/(w-_)+/.local/share/Steam/steamapps/"
      ];
      updater.enable = true;
      fangfrisch.enable = cfg.clamav.fangfrisch;

      scanner = {
        enable = true;

        # run weekly or daily
        interval = mkIf (!cfg.clamav.daily) "Mon, *-*-* 04:00:00";
      };
    };

    # only run clamdscan when AC is connected
    systemd.services.clamdscan.unitConfig.ConditionACPower = true;

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

    # acme
    security.acme = mkIf cfg.acme.enable {
      acceptTerms = true;
      defaults = {
        email = "acme-${hostname}@gabe.super.fish";
        dnsResolver = "1.1.1.1:53";
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare_acme.path;
      };
      # ssl certs for each host
      certs = {
        "${hostname}.${domain}" = {
          domain = "${hostname}.${domain}";
          extraDomainNames = [ "*.${hostname}.${domain}" ];
          group =
            mkIf config.services.traefik.enable config.services.traefik.group;
        };
      };
    };

    sops.secrets.cloudflare_acme.sopsFile = ../../../hosts/common/secrets.yaml;
  };
}
