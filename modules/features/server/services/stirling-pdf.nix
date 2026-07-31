{
  den.aspects.stirling-pdf.nixos = {
    network.services.stirling = 8844;

    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = 8844;
        DISABLE_ADDITIONAL_FEATURES = "false";
      };
    };
  };
}
