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

        serviceNames = lib.attrNames cfg.services;
        invalidServiceNames = lib.filter (
          name: builtins.match "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?" name == null
        ) serviceNames;
      in
      {
        options.network = {
          services = lib.mkOption {
            type = lib.types.attrsOf lib.types.port;
            default = { };
            description = "Local HTTP services keyed by DNS-safe service name and assigned loopback port.";
          };

          finalServices = lib.mkOption {
            type = lib.types.attrsOf lib.types.port;
            readOnly = true;
            description = "Resolved local HTTP service catalog shared by ingress providers.";
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

        config = {
          assertions = [
            {
              assertion = invalidServiceNames == [ ];
              message = "network.services contains invalid DNS labels: ${toString invalidServiceNames}";
            }
          ];

          network = {
            ip = hostCfg.ip;

            hostIP = lib.mkIf (!cfg.isHost) self.nixosConfigurations.${domainHost}.config.network.hostIP;

            finalServices = cfg.services;
          };
        };
      };

    provides.server.nixos = { config, ... }: {
      network = {
        isHost = true;
        hostIP = lib.mkForce config.network.ip;
      };
    };
  };
}
