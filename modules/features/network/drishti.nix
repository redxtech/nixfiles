{ self, inputs, ... }:

{
  den.aspects.drishti = {
    nixos = { host, config, ... }: {
      network.services.drishti =
        config.home-manager.users.${host.settings.base.primaryUser}.services.drishti.port;
    };

    homeManager =
      {
        inputs',
        host,
        lib,
        ...
      }:
      {
        imports = [ inputs.drishti.homeManagerModules.default ];
        services.drishti = {
          enable = true;
          package = inputs'.drishti.packages.default;
          # map all hosts except nixiso
          hosts = map (h: "${host.settings.base.primaryUser}@${h}") (
            lib.filter (name: name != "nixiso") (lib.attrNames self.nixosConfigurations)
          );
        };
      };
  };

  flake-file.inputs.drishti.url = "github:srid/drishti";
}
