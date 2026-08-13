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
          version = "1.43.3.10861-07dfddaeb";
          name = "${old.pname}-${version}";

          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/1.43.3.10861-07dfddaeb/debian/plexmediaserver_1.43.3.10861-07dfddaeb_amd64.deb";
            hash = "sha256-s8OpELTLfdincYQZawp76rsZx5AQXMR6+algH/Ev0zI=";
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
