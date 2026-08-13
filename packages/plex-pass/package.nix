{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      updateScript = pkgs.writeShellApplication {
        name = "update-plex-pass";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          python3
        ];
        text = ''
          ${./update.sh} packages/plex-pass/package.nix
        '';
      };
    in
    {
      packages = {
        plex-pass-raw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.2.10687-563d026ea";
          name = "${old.pname}-${version}";

          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            hash = "sha256-dgkj0Uny/d0DnExgYWjxfl2cFsiattlGzb7Guzmtro4=";
          };

          passthru = (old.passthru or { }) // {
            updateScript = pkgs.lib.getExe updateScript;
          };
        });

        plex-pass = (pkgs.plex.override { plexRaw = self'.packages.plex-pass-raw; }).overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            updateScript = pkgs.lib.getExe updateScript;
          };
        });
      };
    };
}
