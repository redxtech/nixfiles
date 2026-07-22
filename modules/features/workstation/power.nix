{
  den.aspects.power = {
    nixos =
      { host, lib, ... }:
      let
        cfg = host.settings.workstation;
      in
      lib.mkMerge [
        {
          services.upower.enable = true;
        }

        # laptop-specific power management
        (lib.mkIf cfg.isLaptop {
          services.power-profiles-daemon.enable = true;

          # disable others
          # TODO: use auto-cpufreq, need to add support to noctalia
          services.auto-cpufreq.enable = false;
          services.tlp.enable = false;
        })
      ];
  };
}
