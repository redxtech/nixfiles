{ self, ... }:

{
  den.aspects.tautulli.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.tautulli = {
        image = "lscr.io/linuxserver/tautulli:latest";
        labels = mkAllLabels "tautulli" {
          name = "tautulli";
          group = "monitoring";
          icon = "tautulli.svg";
          href = "https://tautulli.${config.networking.fqdn}";
          desc = "plex stats page";
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPorts 8181) ];
        volumes = [
          ((self.lib.server.volumes server).config "tautulli")
          "${server.configRoot}/plex/Plex Media Server/Logs:/Logs"
        ];
      };
    };
}
