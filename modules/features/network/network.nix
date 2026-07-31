{
  den,
  self,
  lib,
  ...
}:

{
  den.aspects.network = {
    settings.ip = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.1.100";
      description = "Internal IP address to use";
    };

    includes = [
      den.aspects.monitoring
      den.aspects.traefik
    ];

    nixos =
      { host, config, ... }:
      let
        hostCfg = host.settings.network;
        cfg = config.network;

        realHosts = lib.filter (host: host != "nixiso") (lib.attrNames self.nixosConfigurations);
        domainHost = lib.findFirst (
          host: self.nixosConfigurations.${host}.config.network.isHost
        ) null realHosts;
      in
      {
        options.network = {
          services = lib.mkOption {
            type = lib.types.attrsOf lib.types.port;
            default = { };
            description = "Services to enable port assignments";
          };

          finalServices = lib.mkOption {
            type = lib.types.attrsOf lib.types.port;
            readOnly = true;
            description = "Final combined set of services";
          };

          isHost = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the system is a host";
          };

          hostIP = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "The IP address of the host";
          };

          ip = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            readOnly = true;
            description = "The IP address of the host";
          };
        };

        config.network = {
          ip = hostCfg.ip;

          hostIP = lib.mkIf (!cfg.isHost) self.nixosConfigurations.${domainHost}.config.network.hostIP;

          finalServices = cfg.services;
        };
      };

    provides.server.nixos = { config, ... }: {
      network = {
        isHost = true;
        hostIP = lib.mkForce config.network.ip;

        services.dash = 4000;
      };
    };
  };
}
