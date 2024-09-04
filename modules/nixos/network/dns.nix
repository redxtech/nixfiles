{ config, self, lib, pkgs, hostnames, ... }:

let
  cfg = config.network;
  enabled = cfg.enable && cfg.isHost;

  inherit (cfg) address domain hostIP;

  port = toString 53;
  prometheusPort = toString 3201;
in {
  config = lib.mkIf enabled {
    services.coredns = {
      enable = true;

      config = let
        enabledHosts = builtins.filter (host:
          host != "nixiso"
          && self.nixosConfigurations.${host}.config.network.enable) hostnames;

        zonePairs = map (hostname: {
          inherit hostname;
          inherit (self.nixosConfigurations.${hostname}.config.network) ip;
        }) enabledHosts;

        mkZoneFile = hostname: ip:
          pkgs.writeText "${hostname}.${domain}.zone" ''
            $TTL 3600

            $ORIGIN ${hostname}.${domain}.
            @     IN      SOA    ns.${hostname}.${domain}. info.${domain}. (
                                 2024090300      ; serial
                                 12h             ; refresh
                                 15m             ; retry
                                 3w              ; expire
                                 2h              ; minimum ttl
                                 )

                  IN      NS     ns.${hostname}.${domain}.

            ns    IN      A      ${ip}

            ; -- add dns records below

            @     IN      A      ${ip}
            *     IN      A      ${ip}
          '';

        zoneEntries = map ({ hostname, ip }: ''
          ${hostname}.${domain}:${port} {
            file ${mkZoneFile hostname ip}
            prometheus 127.0.0.1:${prometheusPort}
            log
          }
        '') zonePairs;
      in ''
        .:${port} {
          forward . tls://${hostIP} { tls_servername dns.${address} }
          prometheus 127.0.0.1:${prometheusPort}
          cache
          log
        }

        ${lib.concatStringsSep "\n" zoneEntries}
      '';
    };

    networking = {
      resolvconf.useLocalResolver = false;

      firewall.allowedTCPPorts = [ 53 ];
      firewall.allowedUDPPorts = [ 53 ];
    };
  };
}
