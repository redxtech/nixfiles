{ config, self, lib, hostnames, ... }:

let
  cfg = config.network;
  inherit (lib) mkIf;
  inherit (builtins) filter head;

  host = mkIf cfg.isHost;
  realHosts = filter (host: host != "nixiso") hostnames;
  domainHost = head
    (filter (host: self.nixosConfigurations.${host}.config.network.isHost)
      realHosts);
in {
  imports = [ ./dns.nix ./traefik.nix ./tunnel.nix ];

  options.network = let inherit (lib) mkOption types;
  in with types; {
    enable = lib.mkEnableOption "Enable network configuration";

    domain = mkOption {
      type = str;
      default = "sucha.foo";
      description = "Domain to use for DNS services";
    };

    hostname = mkOption {
      type = str;
      readOnly = true;
      description = "Hostname to use for DNS services";
    };

    address = mkOption {
      type = str;
      readOnly = true;
      description = "Address to use for DNS services";
    };

    isHost = mkOption {
      type = bool;
      default = false;
      description = "Whether the system is a host";
    };

    ip = mkOption {
      type = str;
      default = null;
      example = "192.168.1.100";
      description = "Internal IP address to use";
    };

    hostIP = mkOption {
      type = nullOr str;
      readOnly = true;
      description = "The IP address of the host";
    };

    tunnelID = mkOption {
      type = str;
      default = "";
      description = "The default tunnel ID to use.";
    };

    services = mkOption {
      type = attrsOf port;
      default = { };
      description = "Services to enable";
    };

    finalServices = mkOption {
      type = attrsOf port;
      readOnly = true;
      description = "Final combined set of services";
    };
  };

  config = mkIf cfg.enable {
    network = {
      hostname = config.networking.hostName;
      address = "${config.networking.hostName}.${cfg.domain}";

      hostIP = if (!cfg.isHost) then
        self.nixosConfigurations.${domainHost}.config.network.hostIP
      else
        cfg.ip;

      finalServices = cfg.services // {
        # universal services
        alloy = 12346;
        cockpit = 9090;
        traefik = 8080;

        # host only
        dash = host 4000;
        grafana = host 3000;
        prometheus = host 9090;
        loki = host 3002;
      };
    };
  };
}

