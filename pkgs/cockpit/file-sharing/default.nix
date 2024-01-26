{ lib, stdenv, dpkg, fetchurl }:
let

in stdenv.mkDerivation rec {
  pname = "cockpit-file-sharing";
  version = "3.3.4";

  src = fetchurl {
    url =
      "https://github.com/45Drives/cockpit-file-sharing/releases/download/v${version}/cockpit-file-sharing_${version}-1focal_all.deb";
    sha256 = "sha256-/XXuFpAVlkLeNmOHC0bvxbsl3d+YPhoXJsAInUsM8n4=";
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
    maintainers = with lib.maintainers; [ ];
    platforms = platforms.linux;
  };
}
