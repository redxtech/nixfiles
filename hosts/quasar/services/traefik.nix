{ config, ... }:

let
  cfg = config.nas;
  inherit (config.network) address;
in {
  services.traefik = {
    dataDir = cfg.paths.config + "/traefik";

    dynamicConfigOptions = {
      tls = let
        dir = config.security.acme.certs."adguard.${address}".directory;
        cert = {
          certFile = "${dir}/cert.pem";
          keyFile = "${dir}/key.pem";
        };
      in {
        certificates = [ cert ];
        stores.default.defaultCertificate = cert;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
