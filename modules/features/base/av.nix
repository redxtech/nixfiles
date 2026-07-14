{ lib, ... }:

{
  den.aspects.av.nixos =
    {
      host,
      config,
      pkgs,
      ...
    }:
    {
      services.clamav = {
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

        updater.enable = config.services.clamav.daemon.enable;
        fangfrisch.enable = config.services.clamav.daemon.enable;

        scanner = {
          enable = true;

          # run daily on laptops (instead of weekly)
          interval = lib.mkIf (host.settings.workstation.isLaptop) "Mon, *-*-* 04:00:00";
        };
      };

      # only run clamdscan when AC is connected
      systemd.services.clamdscan.unitConfig.ConditionACPower = true;

      # install gui app if a desktop
      environment.systemPackages = lib.optional host.settings.base.hasDisplay pkgs.clamtk;
    };
}
