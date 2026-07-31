{ self, ... }:

{
  den.aspects.jdownloader.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
    in
    {
      virtualisation.oci-containers.containers.jdownloader = {
        image = "jlesage/jdownloader-2:latest";
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            USER_ID = toString server.uid;
            GROUP_ID = toString server.gid;
            KEEP_APP_RUNNING = "1";
            WEB_LISTENING_PORT = "5800";
          };
        environmentFiles = [ config.sops.secrets.jdownloader_env.path ];
        ports = [ (mkPorts 5800) ];
        volumes = [
          ((self.lib.server.volumes server).config "jdownloader")
          "${server.downloadsRoot}/jdownloader:/output"
        ];
      };

      sops.secrets.jdownloader_env.sopsFile = server.legacySopsFile;
    };
}
