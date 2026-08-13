{ self, ... }:

{
  den.aspects.qbittorrent.nixos =
    {
      config,
      host,
      pkgs,
      ...
    }:
    let
      server = host.settings.server;
      environment = self.lib.server.defaultEnvironment {
        uid = server.uid;
        gid = server.gid;
        timeZone = config.time.timeZone;
      };
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;

      mkQbittorrent =
        {
          name,
          route,
          webPort,
          torrentPort,
          configDir,
          downloadsDir,
          description,
          widgetUser,
          widgetPassword,
        }:
        {
          image = "lscr.io/linuxserver/qbittorrent:latest";
          labels = mkAllLabels route webPort {
            inherit name;
            group = "download";
            icon = "qbittorrent.svg";
            href = "https://${route}.${config.networking.fqdn}";
            desc = description;
            widget = {
              type = "qbittorrent";
              url = "https://${route}.${config.networking.fqdn}";
              username = widgetUser;
              password = widgetPassword;
            };
          };
          environment = environment // {
            WEBUI_PORT = toString webPort;
            TORRENTING_PORT = toString torrentPort;
          };
          ports = [
            (mkPorts webPort)
            (mkPorts torrentPort)
            "${mkPorts torrentPort}/udp"
          ];
          volumes = [
            "${server.configRoot}/${configDir}:/config"
            "${server.downloadsRoot}/${downloadsDir}:/downloads"
            "${pkgs.vuetorrent}/share/vuetorrent:/vuetorrent:ro"
          ];
        };
    in
    {
      virtualisation.oci-containers.containers = {
        qbit = mkQbittorrent {
          name = "qbit";
          route = "torrent";
          webPort = 8811;
          torrentPort = 46881;
          configDir = "qbit";
          downloadsDir = "deluge";
          description = "torrent client";
          widgetUser = "{{HOMEPAGE_VAR_QBIT_USER}}";
          widgetPassword = "{{HOMEPAGE_VAR_QBIT_PASS}}";
        };

        qbit-alt = mkQbittorrent {
          name = "qbit alt";
          route = "qbit";
          webPort = 8810;
          torrentPort = 6882;
          configDir = "qbit-alt";
          downloadsDir = "qbit";
          description = "alternate torrent client";
          widgetUser = "{{HOMEPAGE_VAR_QBIT_ALT_USER}}";
          widgetPassword = "{{HOMEPAGE_VAR_QBIT_ALT_PASS}}";
        };
      };
    };
}
