{
  nas = {
    enable = true;
    paths.config = "/config/pods";
  };

  network.services.uptime = 3301;

  # disable sudo password on server
  security.sudo.wheelNeedsPassword = false;
}
