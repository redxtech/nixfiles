{ config, pkgs, lib, ... }:

with lib;
let cfg = config.nas;
in {
  services.traefik = {
    enable = true;

    dataDir = cfg.paths.config + "/traefik";
    group = "docker";

    environmentFiles = [ config.sops.secrets.cloudflare_secrets.path ];

    staticConfigOptions = {
      api.insecure = true;
      api.dashboard = true;

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
              main = "${cfg.domain}";
              sans = [ "*.${cfg.domain}" ];
            }];
          };
        };
      };

      certificatesResolvers = {
        cloudflare = {
          acme = {
            email = "gabe+quasar-letsencrypt@sent.at";
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

    dynamicConfigOptions = {
      http = {
        routers = {
          portainer = {
            rule = "Host(`portainer.${cfg.domain}`)";
            service = "portainer";
            entrypoints = [ "websecure" ];
          };
          sonarr = {
            rule = "Host(`sonarr.${cfg.domain}`)";
            service = "sonarr";
            entrypoints = [ "websecure" ];
          };
          radarr = {
            rule = "Host(`radarr.${cfg.domain}`)";
            service = "radarr";
            entrypoints = [ "websecure" ];
          };
        };
        services = {
          portainer.loadBalancer.servers = [{ url = "http://localhost:9000"; }];
          sonarr.loadBalancer.servers = [{ url = "http://localhost:8989"; }];
          radarr.loadBalancer.servers = [{ url = "http://localhost:7878"; }];
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  sops.secrets.cloudflare_secrets.sopsFile = ../secrets.yaml;
  sops.secrets.cloudflare_secrets.owner = "traefik";
}
