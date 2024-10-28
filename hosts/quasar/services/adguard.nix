{ config, self, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;

  inherit (cfgNet) address;
  inherit (self.lib.containers) mkPorts;
  inherit (self.lib.containers.labels.traefik address) mkAllLabelsPort mkTLRstr;

  name = "adguard";
  host = "${name}.${address}";
  hostDNS = "dns.${address}";
  port = toString cfg.ports.adguard;
  portDNS = toString cfg.ports.adguarddns;
  webports = mkPorts port;

  defaultEnv = {
    PUID = toString config.users.users.${cfg.user}.uid;
    PGID = toString config.users.groups.${cfg.group}.gid;
    TZ = cfg.timezone;
  };
in {
  virtualisation.oci-containers.containers = {
    adguard = {
      image = "adguard/adguardhome:latest";
      environment = defaultEnv;

      labels = removeAttrs (mkAllLabelsPort "adguard" port {
        name = "adguard";
        group = "network";
        icon = "adguard-home.svg";
        href = "https://adguard.${address}";
        desc = "dns level adblocking";
        weight = -90;
        widget = {
          type = "adguard";
          url = "https://adguard.${address}";
          username = "{{HOMEPAGE_VAR_ADGUARD_USER}}";
          password = "{{HOMEPAGE_VAR_ADGUARD_PASS}}";
        };
      } // {
        "${mkTLRstr name}.rule" =
          "HostRegexp(`^([a-z-]+\\.)?(${host}|${hostDNS})$`)";
      }) [ "${mkTLRstr name}.tls.certresolver" ];

      ports = [
        webports # frontend
        "${portDNS}:53/tcp" # DNS
        "${portDNS}:53/udp" # DNS
        # "67:67/udp" # DHCP
        # "68:68/tcp" # DHCP
        # "68:68/udp" # DHCP
        # "80:80/tcp" # DNS over HTTPS
        "1443:1443/tcp" # DNS over HTTPS
        "1443:1443/udp" # DNS over HTTPS
        "784:784/udp" # DNS over QUIC
        "853:853/udp" # DNS over QUIC
        "853:853/tcp" # DNS over TLS
        "8853:8853/udp" # DNS over QUIC
        # "5443:5443/tcp" # DNScrypt
        # "5443:5443/udp" # DNScrypt
      ];

      volumes = [
        "${toString cfg.paths.config}/adguard/conf:/opt/adguardhome/conf"
        "${toString cfg.paths.config}/adguard/work:/opt/adguardhome/work"
        "${
          config.security.acme.certs."${name}.${address}".directory
        }:/certs/${host}"
      ];
    };

    adguard-exporter = {
      image = "docker.io/ebrianne/adguard-exporter:latest";
      environment = defaultEnv // {
        adguard_protocol = "http";
        adguard_hostname = "127.0.0.1";
        adguard_port = port;
        interval = "10s";
        log_limit = "10000";
        server_port = toString cfg.ports.adguard-exporter;
      };
      environmentFiles = [ config.sops.secrets.adguard_exporter.path ];
      ports = [ (mkPorts cfg.ports.adguard-exporter) ];
      extraOptions = [ "--network" "host" ];
    };
  };

  security.acme.certs = {
    "${host}" = {
      domain = host;
      extraDomainNames = [ "*.${host}" hostDNS "*.${hostDNS}" ];
      inherit (config.services.traefik) group;
    };
  };

  sops.secrets.adguard_exporter.sopsFile = ../secrets.yaml;

  networking.firewall = {
    allowedTCPPorts = [ 853 ];
    allowedUDPPorts = [ 853 ];
  };
}
