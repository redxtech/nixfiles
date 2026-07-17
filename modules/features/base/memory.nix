{
  den.aspects.memory.nixos = { config, ... }: {
    # TODO: test if earlyoom is better than oomd
    services.earlyoom = {
      enable = true;
      enableNotifications = true;
    };

    systemd.oomd.enable = false;

    # optimize ram to prevent having to use oom
    zramSwap.enable = true;
  };
}
