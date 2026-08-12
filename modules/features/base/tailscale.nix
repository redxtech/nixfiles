{ lib, ... }:

{
  den.aspects.tailscale = {
    settings.tailnet = lib.mkOption {
      type = lib.types.str;
      default = "colobus-pirate.ts.net";
      description = "The tailnet to use.";
    };

    nixos =
      { config, lib, ... }:
      {
        services.tailscale =
          let
            flags = [
              "--advertise-exit-node"
              "--ssh"
            ];
          in
          {
            enable = true;
            authKeyFile = config.sops.secrets.tailscale-init-authkey.path;

            openFirewall = true;
            useRoutingFeatures = lib.mkDefault "both";
            extraUpFlags = flags;
            extraSetFlags = flags;
          };

        # firewall for tailscale
        networking.firewall = {
          checkReversePath = "loose";
          allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
        };

        sops.secrets.tailscale-init-authkey.sopsFile = ../../../secrets/hosts/common/secrets.yaml;
      };

    provides.server.nixos =
      { config, ... }:
      let
        services = config.network.finalServices;
        mkServeService = port: {
          endpoints."tcp:443" = "http://127.0.0.1:${toString port}";
          advertised = true;
        };
      in
      lib.mkIf (services != { }) {
        # the service keys become stable tailnet DNS names. nix owns the
        # complete serve configuration, so removing a key removes its route.
        services.tailscale.serve = {
          enable = true;
          services = lib.mapAttrs (_name: port: mkServeService port) services;
        };
      };
  };
}
