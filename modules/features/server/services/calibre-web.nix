{ self, ... }:

{
  den.aspects.calibre-web.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels mkTLRstr;
    in
    {
      virtualisation.oci-containers.containers.calibre-web = {
        image = "crocodilestick/calibre-web-automated:latest";
        labels =
          mkAllLabels "books" {
            name = "calibre web";
            group = "books";
            icon = "calibre-web.svg";
            href = "https://books.${config.networking.fqdn}";
            desc = "ebook manager";
            weight = -90;
            widget = {
              type = "calibreweb";
              url = "https://books.${config.networking.fqdn}";
              username = "{{HOMEPAGE_VAR_CALIBREWEB_USERNAME}}";
              password = "{{HOMEPAGE_VAR_CALIBREWEB_PASSWORD}}";
            };
          }
          // {
            "${mkTLRstr "books"}.middlewares" = "homeassistant-allow-iframe@file";
          };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:universal-package-install";
            INSTALL_PIP_PACKAGES = "jsonschema";
          };
        environmentFiles = [ config.sops.secrets.CALIBRE_WEB_HARDCOVER_KEY.path ];
        ports = [ (mkPorts 8083) ];
        volumes = [
          ((self.lib.server.volumes server).config "calibre-web")
          "${server.configRoot}/calibre/Calibre Library:/calibre-library"
          "${server.configRoot}/calibre-web-ingest:/cwa-book-ingest"
        ];
      };

      sops.secrets.CALIBRE_WEB_HARDCOVER_KEY.sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
    };
}
