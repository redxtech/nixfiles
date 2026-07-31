{
  den.aspects.prometheus.nixos = { config, ... }: {
    monitoring.isHost = true;
    network.services.prometheus = config.services.prometheus.port;

    services.prometheus = {
      enable = true;
      port = 3001;
      extraFlags = [ "--web.enable-remote-write-receiver" ];
    };
  };
}
