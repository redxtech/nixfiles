{ lib, ... }:

{
  mkSecretsFileOption =
    service:
    lib.mkOption {
      type = lib.types.path;
      description = "SOPS file containing secrets for ${service}.";
    };

  volumes = server: {
    config = name: "${server.configRoot}/${name}:/config";
    data = name: "${server.dataRoot}/${name}:/data";
    downloads = name: "${server.downloadsRoot}/${name}:/downloads";
    allDownloads = "${server.downloadsRoot}:/downloads";
    media = "${server.mediaRoot}:/media";
  };

  defaultEnvironment =
    {
      uid,
      gid,
      timeZone,
    }:
    {
      PUID = toString uid;
      PGID = toString gid;
      TZ = timeZone;
    };
}
