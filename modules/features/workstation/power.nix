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
          # choose auto-cpufreq over the power management options
          services.auto-cpufreq.enable = true;

          # disable others
          services.power-profiles-daemon.enable = false;
          services.tlp.enable = false;
        })
      ];
  };
}
