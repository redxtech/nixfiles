{ lib, stdenv, dpkg, fetchurl }:
let

in stdenv.mkDerivation rec {
  pname = "cockpit-file-sharing";
  version = "4.3.1-2";

  src = fetchurl {
    url =
      "https://github.com/45Drives/cockpit-file-sharing/releases/download/v${version}/cockpit-file-sharing_${version}bookworm_all.deb";
    hash = "sha256-EuWJhbMfyd9xdUyS8HRD+kF1Sb5/K90Bj1pEbdcmn/U=";
  };

  nativeBuildInputs = [ dpkg ];

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
}
