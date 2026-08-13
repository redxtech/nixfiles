{ lib, ... }:

{
  den.aspects.tailscale = {
    settings.tailnet = lib.mkOption {
      type = lib.types.str;
      default = "colobus-pirate.ts.net";
      description = "The tailnet to use.";
    };

    settings.advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Tailscale tags advertised by this host.";
    };

    nixos =
      {
        config,
        host,
        lib,
        ...
      }:
      {
        services.tailscale =
          let
            flags = [
              "--advertise-exit-node"
              "--ssh"
            ]
            ++ lib.optional (
              host.settings.tailscale.advertiseTags != [ ]
            ) "--advertise-tags=${lib.concatStringsSep "," host.settings.tailscale.advertiseTags}";
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
        docktailServiceNames = lib.filter (name: name != null) (
          lib.mapAttrsToList (
            _containerName: container: lib.attrByPath [ "labels" "docktail.service.name" ] null container
          ) config.virtualisation.oci-containers.containers
        );
        # docktail owns labeled OCI services; avoid configuring the same
        # tailscale service through both the native serve module and docktail.
        services = removeAttrs config.network.finalServices docktailServiceNames;
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
