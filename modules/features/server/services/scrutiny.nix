{ self, lib, ... }:

{
  den.aspects.scrutiny.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
      devices = map (name: "/dev/${name}") [
        "sda"
        "sdb"
        "sdc"
        "sdd"
        "sde"
        "sdf"
        "sdg"
        "sdh"
        "sdi"
        "sdj"
        "sdk"
        "sdl"
        "sdm"
        "sdn"
        "nvme0"
      ];
    in
    {
      virtualisation.oci-containers.containers.scrutiny = {
        image = "ghcr.io/analogj/scrutiny:master-omnibus";
        labels = mkAllLabels "scrutiny" {
          name = "scrutiny";
          group = "monitoring";
          icon = "scrutiny.svg";
          href = "https://scrutiny.${config.networking.fqdn}";
          desc = "storage health monitoring";
        };
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        ports = [ (mkPort 6080 8080) ];
        volumes = [
          "/run/udev:/run/udev:ro"
          "${server.configRoot}/scrutiny:/opt/scrutiny/config"
          "${server.configRoot}/scrutiny-influx:/opt/scrutiny/influxdb"
        ];
        extraOptions = [
          "--cap-add"
          "SYS_RAWIO"
          "--cap-add"
          "SYS_ADMIN"
        ]
        ++ lib.concatMap (device: [
          "--device"
          device
        ]) devices;
      };
    };
}
