{ den, self, ... }:

let
  cacheHost = "cache.quasar.sucha.foo";
  publicKey = "cache.quasar.sucha.foo-1:avw2bKdcZFvA4wivKF3HipWPSO6R3iW79oykb/xKn5w=";
  clientSettings = {
    substituters = [ "https://${cacheHost}/main" ];
    trusted-public-keys = [ publicKey ];
  };
in
{
  den.aspects.cache = {
    nixos = { pkgs, ... }: {
      nix.settings = clientSettings;
      environment.systemPackages = [ pkgs.attic-client ];
    };

    homeManager.nix.settings = clientSettings;

    provides.server = {
      includes = [ den.aspects.cache ];

      nixos =
        {
          config,
          host,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.atticd;
          stateDir = "${host.settings.server.configRoot}/attic";
          storageDir = "${host.settings.server.dataRoot}/attic";
          tailscaleHost = "attic.${host.settings.tailscale.tailnet}";
          listen = "127.0.0.1:8087";
          serverConfig = (pkgs.formats.toml { }).generate "attic-bootstrap.toml" cfg.settings;
          bootstrap = pkgs.writeShellApplication {
            name = "attic-cache-bootstrap";
            runtimeInputs = [
              cfg.package
              config.nix.package
              pkgs.coreutils
              pkgs.curl
              pkgs.jq
            ];
            text = builtins.readFile ./bootstrap.sh;
          };
          secret = {
            sopsFile = cfg.secretsFile;
            restartUnits = [ "atticd.service" ];
          };
        in
        {
          options.services.atticd.secretsFile = self.lib.server.mkSecretsFileOption "Attic";

          config = {
            network.tailscaleServices.attic = 8087;

            # catalog services also become Tailscale services, so register only the public route here
            services.traefik.dynamicConfigOptions.http = {
              services.cache.loadBalancer.servers = [ { url = "http://${listen}"; } ];
              routers.cache = {
                rule = "Host(`${cacheHost}`)";
                service = "cache";
                entrypoints = [ "websecure" ];
              };
            };

            services.atticd = {
              enable = true;
              environmentFile = config.sops.secrets.attic_server_env.path;
              settings = {
                inherit listen;
                allowed-hosts = [
                  cacheHost
                  tailscaleHost
                  listen
                ];
                api-endpoint = "https://${tailscaleHost}/";
                substituter-endpoint = "https://${cacheHost}/";
                database.url = "sqlite://${stateDir}/server.db?mode=rwc";
                storage = {
                  type = "local";
                  path = storageDir;
                };
                compression.type = "zstd";
                garbage-collection = {
                  interval = "12 hours";
                  default-retention-period = "90 days";
                };
              };
            };

            users.users.atticd = {
              isSystemUser = true;
              group = "atticd";
            };
            users.groups.atticd = { };

            systemd.tmpfiles.rules = [
              "d ${stateDir} 0700 atticd atticd -"
              "d ${storageDir} 0700 atticd atticd -"
            ];

            systemd.services.atticd = {
              after = [ "systemd-tmpfiles-setup.service" ];
              unitConfig.RequiresMountsFor = [
                stateDir
                storageDir
              ];
              serviceConfig = {
                # persistent data outside StateDirectory needs a stable owner
                DynamicUser = lib.mkForce false;
                ReadWritePaths = [ stateDir ];
                LoadCredential = [
                  "cache-signing-key:${config.sops.secrets.attic_cache_signing_key.path}"
                ];
              };
              postStart = ''
                ${lib.getExe bootstrap} ${serverConfig} http://${listen} \
                  "$CREDENTIALS_DIRECTORY/cache-signing-key" ${lib.escapeShellArg publicKey}
              '';
            };

            sops.secrets = {
              attic_server_env = secret;
              attic_cache_signing_key = secret;
            };
          };
        };
    };
  };
}
