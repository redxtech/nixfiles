{ lib, stdenv, fetchFromGitHub, zfs }:

stdenv.mkDerivation rec {
  pname = "cockpit-navigator";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "45Drives";
    repo = "cockpit-zfs-manager";
    rev = "v${version}";
    hash = "sha256-ge3wrri/eG1HprFSBYkjlqLzYOM3S4gUoqyE1w2Grz8=";
  };

  buildInputs = [ zfs ];

  installPhase = ''
      mkdir -p $out/share/cockpit/zfs
    	cp -r zfs/* $out/share/cockpit/zfs
  '';

  meta = with lib; {
    description = "Cockpit UI for managing ZFS";
    license = licenses.lgpl3Only;
    homepage = "https://github.com/45Drives/cockpit-zfs-manager";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

