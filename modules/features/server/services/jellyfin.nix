{ self, ... }:

{
  den.aspects.jellyfin.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      volumes = self.lib.server.volumes server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabelsPort;
    in
    {
      virtualisation.oci-containers.containers.jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        labels = mkAllLabelsPort "jellyfin" 8096 {
          name = "jellyfin";
          group = "media";
          icon = "jellyfin.svg";
          href = "https://jellyfin.${config.networking.fqdn}";
          desc = "media server";
          weight = -90;
          widget = {
            type = "jellyfin";
            url = "https://jellyfin.${config.networking.fqdn}";
            key = "{{HOMEPAGE_VAR_JELLYFIN}}";
            enableBlocks = "true";
            enableNowPlaying = "false";
          };
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            JELLYFIN_PublishedServerUrl = "jellyfin.${config.networking.fqdn}";
            # NVIDIA_VISIBLE_DEVICES = "all";
          };
        ports = [
          (mkPorts 8096)
          (mkPorts 8920)
          "${mkPorts 7359}/udp"
        ];
        volumes = [
          (volumes.config "jellyfin")
          volumes.media
          "${server.configRoot}/calibre/Calibre Library:/books"
        ];
      };
    };
}
