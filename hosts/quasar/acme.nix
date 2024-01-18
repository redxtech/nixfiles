{ lib, config, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "gabe+acme@sent.at";
      # reloadServices = [];
      dnsProvider = "cloudflare";
    };

    certs = {
      "nas.gabedunn.dev" = {
        domain = "nas.gabedunn.dev";
        extraDomainNames = [ "*.nas.gabedunn.dev" ];
        credentialFiles = {
          CF_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare_dns".path;
        };
      };
    };
  };

  sops.secrets."cloudflare_dns" = {
    # owner = config.traefik.certs."nas.gabedunn.dev".user;
    # owner = "acme";
  };
}
