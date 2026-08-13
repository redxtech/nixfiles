{ self, ... }:

{
  den.aspects.booklore.settings.secretsFile = self.lib.server.mkSecretsFileOption "BookLore";

  den.aspects.booklore.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      environment = self.lib.server.defaultEnvironment {
        uid = server.uid;
        gid = server.gid;
        timeZone = config.time.timeZone;
      };
      port = 6060;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers = {
        networks = [ "booklore" ];
        containers = {
          booklore = {
            image = "booklore/booklore:latest";
            labels = mkAllLabels "booklore" port {
              name = "booklore";
              group = "books";
              icon = "book-lore.svg";
              href = "https://booklore.${config.networking.fqdn}";
              desc = "ebook manager";
              weight = -100;
            };
            environment = environment // {
              BOOKLORE_PORT = toString port;
            };
            environmentFiles = [ config.sops.secrets.booklore_env.path ];
            ports = [ (mkPorts port) ];
            volumes = [
              "${server.configRoot}/booklore/config:/data"
              "${server.configRoot}/booklore/bookdrop:/bookdrop"
              "${server.configRoot}/booklore/books:/books"
            ];
            dependsOn = [ "booklore-mariadb" ];
            networks = [ "booklore" ];
          };

          booklore-mariadb = {
            image = "lscr.io/linuxserver/mariadb:11.4.5";
            inherit environment;
            environmentFiles = [ config.sops.secrets.booklore_env.path ];
            volumes = [ "${server.configRoot}/booklore/mariadb:/config" ];
            networks = [ "booklore" ];
            extraOptions = [
              "--health-cmd"
              "mariadb-admin ping -h localhost"
            ];
          };
        };
      };

      sops.secrets.booklore_env.sopsFile = host.settings.booklore.secretsFile;
    };
}
