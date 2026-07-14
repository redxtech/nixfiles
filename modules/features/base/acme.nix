{ lib, ... }:

{
  den.aspects.acme.nixos =
    { host, config, ... }:
    let
      cfg = host.settings.base;
      inherit (cfg) hostname domain;
    in
    {
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "acme-${hostname}@gabe.super.fish";
          dnsResolver = "1.1.1.1:53";
          dnsProvider = "cloudflare";
          environmentFile = config.sops.secrets.cloudflare_acme.path;
        };

        # ssl certs for each host
        certs = {
          "${hostname}.${domain}" = {
            domain = "${hostname}.${domain}";
            extraDomainNames = [ "*.${hostname}.${domain}" ];
            group = lib.mkIf config.services.traefik.enable config.services.traefik.group;
          };
        };
      };

      sops.secrets.cloudflare_acme.sopsFile = ../../../secrets/hosts/common/secrets.yaml;
    };
}
