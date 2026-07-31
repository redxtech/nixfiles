{
  den.aspects.uptime-kuma.nixos = {
    network.services.uptime = 3301;

    services.uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "0.0.0.0";
        UPTIME_KUMA_PORT = "3301";
      };
    };
  };
}
