{ den, self, ... }:

{
  den.aspects.cliproxyapi = {
    settings.secretsFile = self.lib.server.mkSecretsFileOption "CLIProxyAPI";

    nixos =
      {
        config,
        host,
        pkgs,
        ...
      }:
      let
        clientConfigPath = "/etc/cliproxyapi/config.yaml";
        clientPackage = config.services.cliproxyapi.package.overrideAttrs (old: {
          ldflags = old.ldflags ++ [ "-X main.DefaultConfigPath=${clientConfigPath}" ];
        });
      in
      {
        environment.systemPackages = [ clientPackage ];

        environment.etc."cliproxyapi/config.yaml".source =
          (pkgs.formats.yaml { }).generate "cliproxyapi-client.yaml"
            {
              management.base-url = "https://ai-api.${host.settings.tailscale.tailnet}";
            };
      };

    provides.server = {
      includes = [ den.aspects.cliproxyapi ];

      nixos =
        {
          config,
          host,
          lib,
          ...
        }:
        let
          cfg = config.services.cliproxyapi;
          stateDir = "/var/lib/cliproxyapi";
          secret = {
            sopsFile = host.settings.cliproxyapi.secretsFile;
            restartUnits = [ "cliproxyapi.service" ];
          };
        in
        {
          network.tailscaleServices.ai-api = cfg.settings.server.port;

          services.cliproxyapi = {
            enable = true;
            openFirewall = false;
            settings = {
              access.api-keys = [ { _secret = config.sops.secrets.cliproxyapi_api_key.path; } ];
              server.port = 8317;
              logging-to-file = true;
              usage-statistics-enabled = true;
              management = {
                allow-remote = true;
                secret-key._secret = config.sops.secrets.cliproxyapi_management_key.path;
              };
              oauth.auth-dir = "${stateDir}/auth";
            };
          };

          assertions = [
            {
              assertion = config.services.tailscale.enable && config.networking.firewall.enable;
              message = "CLIProxyAPI requires Tailscale and the firewall to be enabled.";
            }
            {
              assertion = !builtins.elem cfg.settings.server.port config.networking.firewall.allowedTCPPorts;
              message = "The CLIProxyAPI port must not be opened on all interfaces.";
            }
          ];

          networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
            cfg.settings.server.port
          ];

          sops.secrets = {
            cliproxyapi_api_key = secret;
            cliproxyapi_management_key = secret;
          };
        };
    };
  };
}
