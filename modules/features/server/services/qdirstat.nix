{ self, ... }:

{
  den.aspects.qdirstat.settings.secretsFile = self.lib.server.mkSecretsFileOption "QDirStat";

  den.aspects.qdirstat.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      port = 9030;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels mkTLRstr;
      secretMount = name: "${config.sops.secrets.${name}.path}:${config.sops.secrets.${name}.path}";
    in
    {
      virtualisation.oci-containers.containers.qdirstat = {
        image = "lscr.io/linuxserver/qdirstat:latest";
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            FILE__CUSTOM_USER = config.sops.secrets.qdirstat_user.path;
            FILE__PASSWORD = config.sops.secrets.qdirstat_pw.path;
            CUSTOM_PORT = toString port;
          };
        labels =
          mkAllLabels "qdirstat" port {
            name = "qdirstat";
            group = "utils";
            icon = "qdirstat.svg";
            href = "https://qdirstat.${config.networking.fqdn}";
            desc = "disk usage statistics";
          }
          // {
            "${mkTLRstr "qdirstat"}.middlewares" = "tinyauth@file";
          };
        ports = [ (mkPorts port) ];
        volumes = [
          ((self.lib.server.volumes server).config "qdirstat")
          (secretMount "qdirstat_user")
          (secretMount "qdirstat_pw")
          "/:/data:ro"
        ];
      };

      sops.secrets = {
        qdirstat_user.sopsFile = host.settings.qdirstat.secretsFile;
        qdirstat_pw.sopsFile = host.settings.qdirstat.secretsFile;
      };
    };
}
