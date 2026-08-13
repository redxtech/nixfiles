{ self, ... }:

{
  den.aspects.papra.settings.secretsFile = self.lib.server.mkSecretsFileOption "Papra";

  den.aspects.papra.nixos =
    { config, host, ... }:
    let
      port = 1221;
      server = host.settings.server;
      configDir = "${server.configRoot}/papra";
      url = "https://papra.${config.networking.fqdn}";
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.papra = {
        image = "ghcr.io/papra-hq/papra:26.6.1-rootless";
        labels = mkAllLabels "papra" port {
          name = "papra";
          group = "media";
          icon = "papra.svg";
          href = url;
          desc = "document archiving";
          weight = -35;
        };
        environment = {
          APP_BASE_URL = url;
          TZ = config.time.timeZone;
        };
        environmentFiles = [ config.sops.secrets.papra_env.path ];
        ports = [ (mkPorts port) ];
        volumes = [ "${configDir}:/app/app-data" ];
        extraOptions = [ "--user=${toString server.uid}:${toString server.gid}" ];
      };

      systemd.tmpfiles.rules = map (directory: "d ${directory} 0750 ${server.user} ${server.group} -") [
        configDir
        "${configDir}/db"
        "${configDir}/documents"
      ];

      sops.secrets.papra_env.sopsFile = host.settings.papra.secretsFile;
    };
}
