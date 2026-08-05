{
  den.aspects.flood.nixos = {
    network.services.flood = 8113;

    services.flood = {
      enable = true;
      port = 8113;
      extraArgs = [ "" ];
    };
  };
}
