{ self, ... }:

{
  den.aspects.tubearchivist.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      environment = self.lib.server.defaultEnvironment {
        uid = server.uid;
        gid = server.gid;
        timeZone = config.time.timeZone;
      };
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers = {
        networks = [ "tubearchivist" ];
        containers = {
          tubearchivist = {
            image = "bbilly1/tubearchivist:latest";
            labels = mkAllLabels "tubearchivist" {
              name = "tubearchivist";
              group = "download";
              icon = "tube-archivist.png";
              href = "https://tubearchivist.${config.networking.fqdn}";
              desc = "youtube downloader";
            };
            environment = environment // {
              ES_URL = "http://tubearchivist-es:9200";
              REDIS_CON = "redis://tubearchivist-redis:6379";
              HOST_UID = toString server.uid;
              HOST_GID = toString server.gid;
              TA_HOST = "https://tubearchivist.${config.networking.fqdn}";
            };
            environmentFiles = [ config.sops.secrets.tubearchivist_env.path ];
            ports = [ (mkPort 8898 8000) ];
            volumes = [
              "${server.configRoot}/tubearchivist/cache:/cache"
              "${server.mediaRoot}/yt:/youtube"
            ];
            dependsOn = [
              "tubearchivist-redis"
              "tubearchivist-es"
            ];
            networks = [ "tubearchivist" ];
          };

          tubearchivist-redis = {
            image = "redis";
            volumes = [ "${server.configRoot}/tubearchivist/redis:/data" ];
            networks = [ "tubearchivist" ];
          };

          tubearchivist-es = {
            image = "bbilly1/tubearchivist-es:latest";
            environment = environment // {
              "ES_JAVA_OPTS" = "-Xms1g -Xmx1g";
              "xpack.security.enabled" = "true";
              "discovery.type" = "single-node";
              "path.repo" = "/usr/share/elasticsearch/data/snapshot";
            };
            environmentFiles = [ config.sops.secrets.tubearchivist_env.path ];
            volumes = [ "${server.configRoot}/tubearchivist/es:/usr/share/elasticsearch/data" ];
            networks = [ "tubearchivist" ];
          };
        };
      };

      sops.secrets.tubearchivist_env.sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
    };
}
