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

    sops.secrets.cloudflared_tunnel_creds = {
      inherit (config.services.cloudflared) group;
      owner = config.services.cloudflared.user;
      sopsFile = ../../../hosts/${cfg.hostname}/secrets.yaml;
    };
  };
}
