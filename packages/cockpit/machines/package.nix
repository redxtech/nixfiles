{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.cockpit-machines =
        let
          inherit (pkgs)
            stdenv
            fetchzip
            gettext
            ;

          pname = "cockpit-machines";
          # later releases require the full source-build recipe used by nixpkgs.
          version = "341";
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchzip {
            url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
            hash = "sha256-Tsv18wAN02zQEerIeHAvfs5e0cIWfi7nQey8n1Hv6HI=";
          };

          nativeBuildInputs = [ gettext ];

          makeFlags = [ "PREFIX=$(out)" ];

          postPatch = ''
            touch pkg/lib/cockpit.js
            touch pkg/lib/cockpit-po-plugin.js
            touch dist/manifest.json
          '';

          dontBuild = true;

          meta = with lib; {
            description = "Cockpit UI for virtual machines";
            license = licenses.lgpl21;
            homepage = "https://github.com/cockpit-project/cockpit-machines";
            platforms = platforms.linux;
            maintainers = with maintainers; [ redxtech ];
          };
        };
    };
}
