{ self, ... }:

{
  den.aspects.syncthing.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      volumes = self.lib.server.volumes server;
      port = 8384;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.syncthing = {
        image = "lscr.io/linuxserver/syncthing:latest";
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        labels = mkAllLabels "syncthing" port {
          name = "syncthing";
          group = "services";
          icon = "syncthing.svg";
          href = "https://syncthing.${config.networking.fqdn}";
          desc = "file syncing";
        };
        ports = [
          (mkPorts port)
          "22000:22000/tcp"
          "22000:22000/udp"
          "21027:21027/udp"
        ];
        volumes = [
          (volumes.config "syncthing")
          (volumes.data "syncthing")
        ];
      };
    };
}
