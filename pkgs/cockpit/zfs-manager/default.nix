{ lib, stdenv, fetchFromGitHub, corepack_20, gettext, nodejs_20 }:

stdenv.mkDerivation rec {
  pname = "cockpit-navigator";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "45Drives";
    repo = "cockpit-zfs-manager";
    rev = "v${version}";
    hash = "sha256-ge3wrri/eG1HprFSBYkjlqLzYOM3S4gUoqyE1w2Grz8=";
  };

  installPhase = ''
      mkdir -p $out/share/cockpit/zfs
    	cp -r zfs/* $out/share/cockpit/zfs
  '';
}

