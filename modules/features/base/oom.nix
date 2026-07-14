{ lib, ... }:

{
  den.aspects.oom.nixos = { config, ... }: {
    # TODO: test if earlyoom is better than oomd
    services.earlyoom = {
      enable = true;
      enableNotifications = true;
    };

    systemd.oomd.enable = false;
  };
}
