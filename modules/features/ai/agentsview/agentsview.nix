{ self, ... }:

{
  den.aspects.agentsview = {
    nixos = { host, config, ... }: {
      network.services.agentsview =
        config.home-manager.users.${host.settings.base.primaryUser}.services.agentsview.port;
    };

    homeManager = { osConfig, ... }: {
      imports = [ self.homeManagerModules.agentsview ];

      services.agentsview = {
        enable = true;
        port = 8081;
        host = "0.0.0.0";
        publicUrl = "https://agentsview.${osConfig.networking.fqdn}";
      };
    };
  };
}
