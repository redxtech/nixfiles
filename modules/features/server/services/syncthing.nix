{ self, ... }:

{
  den.aspects.syncthing.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      volumes = self.lib.server.volumes server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabelsPort;
    in
    {
      virtualisation.oci-containers.containers.syncthing = {
        image = "lscr.io/linuxserver/syncthing:latest";
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        labels = mkAllLabelsPort "syncthing" 8384 {
          name = "syncthing";
          group = "services";
          icon = "syncthing.svg";
          href = "https://syncthing.${config.networking.fqdn}";
          desc = "file syncing";
        };
        ports = [
          (mkPorts 8384)
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
