{ lib, stdenv, dpkg, fetchurl }:
let

in stdenv.mkDerivation rec {
  pname = "cockpit-benchmark";
  version = "2.1.0";

  src = fetchurl {
    url =
      "https://github.com/45Drives/cockpit-benchmark/releases/download/v${version}/cockpit-benchmark_${version}-2focal_all.deb";
    sha256 = "sha256-TLMmDCtPJ1C8k2ArWBpCqFj0y+JiHf9ijRgjftlr8c8=";
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
    description = "Cockpit UI for benchmarking storage";
    homepage = "https://github.com/45Drives/cockpit-benchmark";
    license = licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    platforms = platforms.linux;
  };
}
