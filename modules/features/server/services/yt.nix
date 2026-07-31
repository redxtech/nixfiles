{ self, ... }:

{
  den.aspects.yt.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      path = "${server.configRoot}/yt";
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.yt = {
        image = "ghcr.io/feederbox826/stash-s6:hwaccel-alpine";
        labels = mkAllLabels "yt" {
          name = "youtube";
          group = "media";
          icon = "youtube.svg";
          href = "https://yt.${config.networking.fqdn}";
          desc = "youtube archive i swear";
          weight = -5;
        };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            STASH_PORT = "8899";
            STASH_STASH = "/data/";
            STASH_GENERATED = "/generated/";
            STASH_METADATA = "/metadata/";
            STASH_CACHE = "/cache/";
            INSTALL_PY_DEPS = "true";
          };
        ports = [ (mkPorts 8899) ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${server.mediaRoot}/yt:/yt"
          "${path}/config:/root/.stash"
          "${path}/data:/data"
          "${path}/metadata:/metadata"
          "${path}/cache:/cache"
          "${path}/generated:/generated"
          "${path}/pip-cache:/pip-install"
        ];
      };
    };
}
