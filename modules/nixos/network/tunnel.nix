{ config, lib, pkgs, ... }:

let
  cfg = config.network;
  inherit (cfg) address;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cloudflared ];

    services.cloudflared = {
      enable = true;
      tunnels = {
        # need to run this manually to set up routing to the tunnel:
        # cloudflared tunnel route dns <tunnel name/id> <hostname>
        "${cfg.tunnelID}" = {
          default = "http_status:404";
          ingress = let websecure = "https://localhost";
          in {
            # hostname.domain and service.hostname.domain get handled by traefik
            "${address}" = websecure;
            "*.${address}" = websecure;
          };

          originRequest.noTLSVerify = true;
          credentialsFile = config.sops.secrets.cloudflared_tunnel_creds.path;
        };
      };
    };

    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflared.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.cloudflared.name;
    };

    sops.secrets.cloudflared_tunnel_creds = {
      owner = config.systemd.services.cloudflared.serviceConfig.User;
      sopsFile = ../../../hosts/${cfg.hostname}/secrets.yaml;
    };
  };
}
