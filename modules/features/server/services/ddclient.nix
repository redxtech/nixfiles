{ self, ... }:

{
  den.aspects.ddclient.nixos =
    {
      config,
      host,
      ...
    }:
    let
      server = host.settings.server;
    in
    {
      virtualisation.oci-containers.containers.ddclient = {
        image = "lscr.io/linuxserver/ddclient:latest";
        environment = self.lib.server.defaultEnvironment {
          uid = server.uid;
          gid = server.gid;
          timeZone = config.time.timeZone;
        };
        volumes = [
          "${config.sops.secrets."ddclient.conf".path}:/defaults/ddclient.conf"
        ];
      };

      sops.secrets."ddclient.conf".sopsFile = server.legacySopsFile;
    };
}
