{ self, lib, ... }:

{
  den.aspects.coredns.nixos =
    { config, pkgs, ... }:
    let
      cfg = config.network;
      inherit (config.networking) domain fqdn;

      corednsPort = toString 53;
      prometheusPort = toString 3201;

      enabledHosts = lib.filter (host: self.nixosConfigurations.${host}.config.network.ip != null) (
        lib.attrNames self.nixosConfigurations
      );

      zonePairs = map (hostname: {
        inherit hostname;
        inherit (self.nixosConfigurations.${hostname}.config.network) ip;
      }) enabledHosts;

      mkZoneFile =
        hostname: ip:
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

      zoneEntries = map (
        { hostname, ip }:
        ''
          ${hostname}.${domain}:${corednsPort} {
            file ${mkZoneFile hostname ip}
            prometheus 127.0.0.1:${prometheusPort}
            log
          }
        ''
      ) zonePairs;
    in
    {
      monitoring.scrapeTargets.coredns = 3201;

      services.coredns = {
        enable = true;

        config = ''
          .:${corednsPort} {
            forward . tls://${cfg.hostIP} { tls_servername dns.${fqdn} }
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
