{ lib, ... }:

{
  den.aspects.acme.nixos =
    { host, config, ... }:
    let
      inherit (config.networking) fqdn hostName;
    in
    {
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "acme-${hostName}@gabe.super.fish";
          dnsResolver = "1.1.1.1:53";
          dnsProvider = "cloudflare";
          environmentFile = config.sops.secrets.cloudflare_acme.path;
        };

        # ssl certs for each host
        certs = {
          ${fqdn} = {
            domain = fqdn;
            extraDomainNames = [ "*.${fqdn}" ];
            group = lib.mkIf config.services.traefik.enable config.services.traefik.group;
          };
        };
      };

      sops.secrets.cloudflare_acme.sopsFile = ../../../secrets/hosts/common/secrets.yaml;
    };
}
