{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cockpit-file-sharing =
        let
          inherit (pkgs)
            stdenv
            fetchurl
            dpkg
            ;

          pname = "cockpit-file-sharing";
          version = "4.6.2-3";
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchurl {
            url = "https://github.com/45Drives/cockpit-file-sharing/releases/download/v${version}/cockpit-file-sharing_${version}bookworm_all.deb";
            hash = "sha256-qC/hivRLE30eXN8x/W3Cm3XOSiD6JhuIOB/+HL5pB6U=";
          };

          nativeBuildInputs = [ dpkg ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

          unpackPhase = "true";

          installPhase = ''
            mkdir -p $out deb
            dpkg -x $src deb
            cp -r deb/usr/share $out
            ls -al $out
          '';

          meta = with lib; {
            description = "Cockpit UI for managing shares";
            homepage = "https://github.com/45Drives/cockpit-file-sharing";
            license = licenses.gpl3Only;
            maintainers = with lib.maintainers; [ redxtech ];
            platforms = platforms.linux;
          };
        };
    };
}
