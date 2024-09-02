{ config, self, lib, pkgs, hostnames, ... }:

let
  cfg = config.network;
  enabled = cfg.enable && cfg.isHost;

  inherit (cfg) domain;
in {
  config = lib.mkIf enabled {
    networking.nameservers = [ cfg.hostIP ];

    services.bind = {
      enable = true;

      forwarders = [
        # local adguard home
        "0.0.0.0 port 1053"
      ];

      cacheNetworks =
        [ "10.0.0.0/24" "192.168.50.0/24" "127.0.0.0/24" "::1/128" ];

      zones = let
        mkZone = { name, ip }: {
          name = "${name}.${domain}";
          master = true;
          file = pkgs.writeText "${name}.${domain}.zone" ''
            $TTL 3600

            $ORIGIN ${name}.${domain}.
            @               IN      SOA     ns.${name}.${domain}. info.${domain}. (
                                            2024082302      ; serial
                                            12h             ; refresh
                                            15m             ; retry
                                            3w              ; expire
                                            2h              ; minimum ttl
                                            )

                            IN      NS      ns.${name}.${domain}.

            ns              IN      A       ${ip}

            ; -- add dns records below

            @               IN      A       ${ip}
            *               IN      A       ${ip}
          '';
        };

        enabledHosts = builtins.filter (host:
          host != "nixiso"
          && self.nixosConfigurations.${host}.config.network.enable) hostnames;
        zonePairs = map (host:
          mkZone {
            name = host;
            inherit (self.nixosConfigurations.${host}.config.network) ip;
          }) enabledHosts;
      in zonePairs;
    };

    networking = {
      resolvconf.useLocalResolver = true;

      firewall.allowedTCPPorts = [ 53 ];
      firewall.allowedUDPPorts = [ 53 ];
    };
  };
}
