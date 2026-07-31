{ self, ... }:

{
  den.aspects.adguard.nixos =
    {
      config,
      host,
      ...
    }:
    let
      server = host.settings.server;
      inherit (config.networking) fqdn;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik fqdn) mkAllLabelsPort mkTLRstr;

      name = "adguard";
      adguardHost = "${name}.${fqdn}";
      dnsHost = "dns.${fqdn}";
      port = 9900;
      dnsPort = 1053;
      exporterPort = 3202;
      environment = self.lib.server.defaultEnvironment {
        uid = server.uid;
        gid = server.gid;
        timeZone = config.time.timeZone;
      };
    in
    {
      monitoring.scrapeTargets.adguard = exporterPort;

      virtualisation.oci-containers.containers = {
        adguard = {
          image = "adguard/adguardhome:latest";
          inherit environment;

          labels = removeAttrs (
            mkAllLabelsPort name port {
              name = "adguard";
              group = "network";
              icon = "adguard-home.svg";
              href = "https://${adguardHost}";
              desc = "dns level adblocking";
              weight = -90;
              widget = {
                type = "adguard";
                url = "https://${adguardHost}";
                username = "{{HOMEPAGE_VAR_ADGUARD_USER}}";
                password = "{{HOMEPAGE_VAR_ADGUARD_PASS}}";
              };
            }
            // {
              "${mkTLRstr name}.rule" = "HostRegexp(`^([a-z-]+\\.)?(${adguardHost}|${dnsHost})$`)";
            }
          ) [ "${mkTLRstr name}.tls.certresolver" ];

          ports = [
            (mkPorts port)
            "${toString dnsPort}:53/tcp"
            "${toString dnsPort}:53/udp"
            "1443:1443/tcp"
            "1443:1443/udp"
            "784:784/udp"
            "853:853/udp"
            "853:853/tcp"
            "8853:8853/udp"
          ];

          volumes = [
            "${server.configRoot}/adguard/conf:/opt/adguardhome/conf"
            "${server.configRoot}/adguard/work:/opt/adguardhome/work"
            "${config.security.acme.certs.${adguardHost}.directory}:/certs/${adguardHost}"
          ];
        };

        adguard-exporter = {
          image = "docker.io/ebrianne/adguard-exporter:latest";
          environment = environment // {
            adguard_protocol = "http";
            adguard_hostname = "127.0.0.1";
            adguard_port = toString port;
            interval = "10s";
            log_limit = "10000";
            server_port = toString exporterPort;
          };
          environmentFiles = [ config.sops.secrets.adguard_exporter.path ];
          ports = [ (mkPorts exporterPort) ];
          extraOptions = [
            "--network"
            "host"
          ];
        };
      };

      security.acme.certs.${adguardHost} = {
        domain = adguardHost;
        extraDomainNames = [
          "*.${adguardHost}"
          dnsHost
          "*.${dnsHost}"
        ];
        inherit (config.services.traefik) group;
      };

      sops.secrets.adguard_exporter.sopsFile = server.legacySopsFile;

      networking.firewall = {
        allowedTCPPorts = [ 853 ];
        allowedUDPPorts = [ 853 ];
      };
    };
}
