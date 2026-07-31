{
  den.aspects.flood.nixos = {
    network.services.flood = 8113;

    services.flood = {
      enable = true;
      openFirewall = true;
      port = 8113;
      extraArgs = [ "" ];
    };
  };
}
