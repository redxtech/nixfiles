{ lib, stdenv, fetchzip, gettext }:

stdenv.mkDerivation rec {
  pname = "cockpit-machines";
  version = "305";

  src = fetchzip {
    url =
      "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
    sha256 = "sha256-K9ga9b79po5lBsNuSqkojyugDIw7nnRORcybuJdv3JU=";
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
    maintainers = with maintainers; [ ];
  };
}
