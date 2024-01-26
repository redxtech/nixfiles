{ lib, stdenv, fetchzip, gettext }:

stdenv.mkDerivation rec {
  pname = "cockpit-podman";
  version = "83";

  src = fetchzip {
    url =
      "https://github.com/cockpit-project/cockpit-podman/releases/download/${version}/cockpit-podman-${version}.tar.xz";
    sha256 = "sha256-mFD1xd7C6Adkn6yXlfVvtJ4aKRhL/EFTl9h51Yle+3g=";
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
    description = "Cockpit UI for podman containers";
    license = licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

