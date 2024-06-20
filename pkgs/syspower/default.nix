{ stdenv, fetchFromGitHub, pkg-config, gtkmm4, gtk4-layer-shell, ... }:

stdenv.mkDerivation {
  name = "syspower";

  src = fetchFromGitHub {
    owner = "System64fumo";
    repo = "syspower";
    rev = "6e6eeae551e820351e6e0166103aa6f62cb14a26";
    hash = "sha256-w8nqaEysmSQgQEny0lvygpGkmuE+H/wus/DH6N50k/U=";
  };

  buildInputs = [ stdenv.cc gtkmm4 gtk4-layer-shell pkg-config ];

  installPhase = ''
    mkdir -p $out/bin
    cp syspower $out/bin
  '';
}
