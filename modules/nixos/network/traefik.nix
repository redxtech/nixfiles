{ config, lib, ... }:

let
  cfg = config.network;
  inherit (cfg) hostname address;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
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
              domains = [{
                main = address;
                sans = [ "*.${address}" ];
              }];
            };
            forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
          };
        };
        certificatesResolvers = {
          cloudflare = {
            acme = {
              email = "${hostname}-letsencrypt@gabe.super.fish";
              storage = "${config.services.traefik.dataDir}/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [ "1.1.1.1:53" "1.0.0.1:53" ];
              };
            };
          };
        };

        providers.docker = {
          endpoint = "unix:///var/run/docker.sock";
          exposedByDefault = false;
        };
      };

      dynamicConfigOptions = let
        mkRouter = name: {
          rule = "Host(`${name}.${address}`)";
          service = "${name}";
          entrypoints = [ "websecure" ];
        };

        mkService = port: {
          loadBalancer.servers =
            [{ url = "http://localhost:${toString port}"; }];
        };
      in {
        http = {
          routers = {
            default = {
              rule = "Host(`${address}`)";
              service = "cockpit";
              entrypoints = [ "websecure" ];
            };
          } // builtins.mapAttrs (name: _: mkRouter name) cfg.finalServices;
          services = builtins.mapAttrs (_: mkService) cfg.finalServices;

          serversTransports.ignorecert.insecureSkipVerify = true;
        };
      };
    };

    sops.secrets.cloudflare_traefik_token = {
      sopsFile = ../../../hosts/common/secrets.yaml;
      owner = "traefik";
    };
  };
}

