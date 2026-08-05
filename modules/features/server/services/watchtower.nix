{ self, ... }:

{
  den.aspects.watchtower.settings.secretsFile = self.lib.server.mkSecretsFileOption "Watchtower";

  den.aspects.watchtower.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.watchtower = {
        image = "nickfedor/watchtower:latest";
        labels = mkAllLabels "watchtower" {
          name = "watchtower";
          group = "services";
          icon = "watchtower.svg";
          href = "https://watchtower.${config.networking.fqdn}";
          desc = "docker container updating";
          weight = -100;
          widget = {
            type = "watchtower";
            url = "https://watchtower.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_WATCHTOWER}}";
          };
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            WATCHTOWER_CLEANUP = "true";
            WATCHTOWER_HTTP_API_METRICS = "true";
          };
        environmentFiles = [ config.sops.secrets.watchtower_env.path ];
        ports = [ (mkPort 3400 8080) ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };

      sops.secrets.watchtower_env.sopsFile = host.settings.watchtower.secretsFile;
    };
}
