{ config, pkgs, lib, ... }:

with lib;
let cfg = config.nas;
in {
  services.adguardhome = {
    enable = true;

    openFirewall = true;
    mutableSettings = true;

    settings = {
      bind_host = "0.0.0.0";
      bind_port = cfg.ports.adguard;

      http.address = "0.0.0.0:${toString cfg.ports.adguard}";

      users = [{
        name = "gabe";
        password =
          "$2b$15$ybN5R4tC0LCDKieq10ba2eWWlMbgsD9cy.//CSeD3NXYazfKKs95C";
      }];

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        bind_port = cfg.ports.adguard;
        bootstrap_dns = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
          "9.9.9.9"
          "149.112.112.112"
          "2620:fe::fe"
          "2620:fe::fe:9"
        ];
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        upstream_mode = "load_balance";
        trusted_proxies = [ "127.0.0.0/8" "::1/128" ];

        resolve_clients = true;
        serve_http3 = true;
      };

      filtering = {
        protection_enabled = true;
        safebrowsing_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;

        # rewrites = [{
        #   domain = "";
        #   answer = "";
        # }];
      };

      querylog.enabled = true;
      querylog.interval = "2160h";
      statistics.enabled = true;
      statistics.interval = "2160h";

      # dhcp = {
      #   enabled = false;
      #   interface_name = "enp0s31f6";
      # };

      # tls = {
      #   enabled = false;
      #   server_name = "adguard.${cfg.domain}";
      #   force_https = true;
      #   # TODO: certs
      # };
    };
  };

  services.traefik.dynamicConfigOptions.http =
    lib.mkIf config.services.traefik.enable {
      routers.adguard = {
        rule =
          "HostRegexp(`adguard.${cfg.domain}`, `{subdomain:[a-z]+}.adguard.${cfg.domain}`)";
        service = "adguard";
        entrypoints = [ "websecure" ];
      };
      services.adguard.loadBalancer.servers =
        [{ url = "http://localhost:${toString config.nas.ports.adguard}"; }];
    };
}
