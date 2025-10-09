{ lib, stdenv, dpkg, fetchurl }:

stdenv.mkDerivation rec {
  pname = "cockpit-benchmark";
  version = "2.1.1";

  # todo: build from source? 2.1.2 doesn't provide prebuilt
  src = fetchurl {
    url =
      "https://github.com/45Drives/cockpit-benchmark/releases/download/v${version}/cockpit-benchmark_${version}-1focal_all.deb";
    sha256 = "sha256-6RRjbxU5NbcyjI4WYSaOYyYGYhi9x8ejLlFuJkLhd0M=";
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
    maintainers = with lib.maintainers; [ redxtech ];
    platforms = platforms.linux;
  };
}
