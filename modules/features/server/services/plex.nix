{
  den.aspects.plex.nixos =
    {
      config,
      host,
      self',
      ...
    }:
    {
      network.services.plex = 32400;

      services.plex = {
        enable = true;
        package = self'.packages.plex-pass;
        user = host.settings.server.user;
        group = host.settings.server.group;
        dataDir = "${host.settings.server.configRoot}/plex";
        openFirewall = true;
      };
    };
}
