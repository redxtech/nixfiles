{ lib, ... }:

{
  den.aspects.tunnel = {
    settings.id = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "The default tunnel ID to use.";
    };

    nixos =
      {
        host,
        config,
        pkgs,
        ...
      }:
      let
        cfg = config.networking;
      in
      {
        environment.systemPackages = [ pkgs.cloudflared ];

        services.cloudflared = {
          enable = true;

          tunnels = {
            # need to run this manually to set up routing to the tunnel:
            # cloudflared tunnel route dns <tunnel name/id> <hostname>
            "${host.settings.tunnel.id}" = {
              default = "http_status:404";
              ingress =
                let
                  websecure = "https://localhost";
                in
                {
                  # hostname.domain and service.hostname.domain get handled by traefik
                  "${cfg.fqdn}" = websecure;
                  "*.${cfg.fqdn}" = websecure;
                };

              originRequest.noTLSVerify = true;
              credentialsFile = config.sops.secrets.cloudflared_tunnel_creds.path;
            };
          };
        };

        users.groups.cloudflared = { };
        users.users.cloudflared = {
          isSystemUser = true;
          group = config.users.groups.cloudflared.name;
        };

        systemd.services.cloudflared.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = config.users.users.cloudflared.name;
        };

        sops.secrets.cloudflared_tunnel_creds = {
          owner = config.systemd.services.cloudflared.serviceConfig.User;
          sopsFile = ../../../secrets/hosts/${config.networking.hostName}/secrets.yaml;
        };
      };
  };
}
