{ config, ... }:

let
  cfg = config.nas;
  defaultEnv = {
    PUID = toString config.users.users.${cfg.user}.uid;
    PGID = toString config.users.groups.${cfg.group}.gid;
    TZ = cfg.timezone;
  };

  inherit (config.network) address;

  name = "adguard";
  host = "${name}.${address}";
  hostDNS = "dns.${address}";
  port = toString cfg.ports.adguard;
  portDNS = toString cfg.ports.adguarddns;

  mkPorts = port: "${toString port}:${toString port}";
  webports = mkPorts port;
  mkTLstr = type: "traefik.http.${type}.${name}";
  mkTLRstr = "${mkTLstr "routers"}";
  mkTLSstr = "${mkTLstr "services"}";
in {
  virtualisation.oci-containers.containers = {
    adguard = {
      image = "adguard/adguardhome:latest";
      environment = defaultEnv;

      labels = {
        "traefik.enable" = "true";
        "${mkTLRstr}.entrypoints" = "websecure";
        "${mkTLRstr}.tls" = "true";
        "${mkTLSstr}.loadbalancer.server.port" = "${port}";
        "${mkTLRstr}.rule" =
          "HostRegexp(`^([a-z-]+\\.)?(${host}|${hostDNS})$`)";
      };

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
