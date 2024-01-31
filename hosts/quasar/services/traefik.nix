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
          forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
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

    dynamicConfigOptions = let
      mkRouter = name: {
        rule = "Host(`${name}.${cfg.domain}`)";
        service = "${name}";
        entrypoints = [ "websecure" ];
      };
      mkService = port: {
        loadBalancer.servers = [{ url = "http://localhost:${toString port}"; }];
      };
    in {
      http = {
        routers = {
          portainer = mkRouter "portainer";
          sonarr = mkRouter "sonarr";
          radarr = mkRouter "radarr";
          uptime = mkRouter "uptime";
        };
        services = {
          portainer = mkService 9000;
          sonarr = mkService 8989;
          radarr = mkService 7878;
          uptime = mkService 3001;
        };
        serversTransports.ignorecert.insecureSkipVerify = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  sops.secrets.cloudflare_secrets.sopsFile = ../secrets.yaml;
  sops.secrets.cloudflare_secrets.owner = "traefik";
}
