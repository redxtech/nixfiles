{
  den.aspects.traefik = {
    nixos =
      { config, ... }:
      let
        cfg = config.networking;
      in
      {
        network.services.traefik = 8080;
        monitoring.scrapeTargets.traefik = 8080;

        services.traefik = {
          enable = true;

          group = "docker";
          environmentFiles = [ config.sops.secrets.cloudflare_traefik_token.path ];

          staticConfigOptions = {
            api.insecure = true;
            api.dashboard = true;

            metrics.prometheus = {
              addEntryPointsLabels = true;
              addRoutersLabels = true;
              addServicesLabels = true;
            };

            entryPoints = {
              web = {
                address = ":80";
                http.redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                };
              };

              websecure = {
                address = ":443";
                http.tls = {
                  certResolver = "cloudflare";
                  domains = [
                    {
                      main = cfg.fqdn;
                      sans = [ "*.${cfg.fqdn}" ];
                    }
                  ];
                };
                forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
              };
            };

            certificatesResolvers.cloudflare.acme = {
              email = "${cfg.hostName}-letsencrypt@gabe.super.fish";
              storage = "${config.services.traefik.dataDir}/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [
                  "1.1.1.1:53"
                  "1.0.0.1:53"
                ];
              };
            };

            providers.docker = {
              endpoint = "unix:///var/run/docker.sock";
              exposedByDefault = false;
            };
          };

          dynamicConfigOptions =
            let
              mkRouter = name: {
                rule = "Host(`${name}.${cfg.fqdn}`)";
                service = "${name}";
                entrypoints = [ "websecure" ];
              };

              mkService = port: {
                loadBalancer.servers = [ { url = "http://localhost:${toString port}"; } ];
              };
            in
            {
              http = {
                services = builtins.mapAttrs (_: mkService) config.network.finalServices;
                routers = {
                  default = {
                    rule = "Host(`${cfg.fqdn}`)";
                    service = "cockpit";
                    entrypoints = [ "websecure" ];
                  };
                }
                // builtins.mapAttrs (name: _: mkRouter name) config.network.finalServices;

                serversTransports.ignorecert.insecureSkipVerify = true;
              };
            };
        };

        sops.secrets.cloudflare_traefik_token = {
          sopsFile = ../../../secrets/hosts/common/secrets.yaml;
          owner = "traefik";
        };
      };

    provides.server.nixos =
      { config, host, ... }:
      let
        inherit (config.networking) fqdn;
        certificateDirectory = "/var/lib/acme/adguard.${fqdn}";
        certificate = {
          certFile = "${certificateDirectory}/cert.pem";
          keyFile = "${certificateDirectory}/key.pem";
        };
      in
      {
        services.traefik = {
          dataDir = "${host.settings.server.configRoot}/traefik";

          dynamicConfigOptions = {
            tls = {
              certificates = [ certificate ];
              stores.default.defaultCertificate = certificate;
            };

            http.middlewares.homeassistant-allow-iframe.headers = {
              contentSecurityPolicy = "frame-ancestors ha.${fqdn}";
              customResponseHeaders = {
                "X-Frame-Options" = "";
                "X-XSS-Protection" = "1";
              };
            };
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
  };
}
