{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cockpit-podman =
        let
          inherit (pkgs)
            stdenv
            fetchzip
            gettext
            ;

          pname = "cockpit-podman";
          version = "132";
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchzip {
            url = "https://github.com/cockpit-project/cockpit-podman/releases/download/${version}/cockpit-podman-${version}.tar.xz";
            hash = "sha256-yWFmpQKnWM/gl73g6ej+kxexOXNbs1qMZcxtSTviCIo=";
          };

          nativeBuildInputs = [ gettext ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

          makeFlags = [ "PREFIX=$(out)" ];

          postPatch = ''
            touch pkg/lib/cockpit.js
            touch pkg/lib/cockpit-po-plugin.js
            # keep the release's prebuilt frontend newer than its patched inputs
            touch runtime-npm-modules.txt
          '';

          dontBuild = true;

          meta = with lib; {
            description = "Cockpit UI for podman containers";
            license = licenses.lgpl21;
            homepage = "https://github.com/cockpit-project/cockpit-podman";
            platforms = platforms.linux;
            maintainers = with maintainers; [ redxtech ];
          };
        };
    };
}
