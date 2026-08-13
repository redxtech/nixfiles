{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
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
          version = "355";
        in
        stdenv.mkDerivation {
          inherit pname version;

          # TODO: update to latest release
          src = fetchzip {
            url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
            hash = "sha256-lXd3/NkGP76qmFphNCFPIHyMTT6qDULt5uVMdCrcQy8=";
          };

          nativeBuildInputs = [ gettext ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

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
