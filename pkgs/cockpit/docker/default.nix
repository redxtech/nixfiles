{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "cockpit-docker";
  version = "2.0.3";

  src = fetchzip {
    url =
      "https://github.com/mrevjd/cockpit-docker/releases/download/v${version}/cockpit-docker.tar.gz";
    sha256 = "sha256-rm3ySTk8W7oUb8sK/oYe5l6S0H01JSaUqIrQkda1U6M=";
  };

  installPhase = ''
    mkdir -p $out/share/cockpit

    cp -r $src $out/share/cockpit/docker
  '';

  dontBuild = true;

  meta = with lib; {
    description = "Cockpit UI for docker containers";
    license = licenses.lgpl21;
    homepage = "https://github.com/mrevjd/cockpit-docker";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

