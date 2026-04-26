{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages = {
        plexPassRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.1.10611-1e34174b1";
          name = "${old.pname}-${version}";

          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            hash = "sha256-pr1+VSObX0sBl/AddeG/+2dIbNdc+EtnvCzy4nTXVn8=";
          };
        });

        plexPass = pkgs.plex.override {
          plexRaw = self'.packages.plexPassRaw;
        };
      };
    };
}
