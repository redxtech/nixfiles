{ lib, config, ... }:

let cfg = config.nas;
in {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "gabe+acme@sent.at";
      dnsResolver = "1.1.1.1:53";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare_acme".path;
    };
  };

  sops.secrets."cloudflare_acme".sopsFile = ./secrets.yaml;
}
