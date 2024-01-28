{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "cockpit-navigator";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "leroycep";
    repo = "cockpit-zfs-manager";
    rev = "816af25099fccc46a3bff5f831b39d98ef33d514";
    hash = "sha256-aLdsHHVVG6eJrvh3B4grZkDEbCZyDJjX2PuKkON8UcI=";
  };

  installPhase = ''
      mkdir -p $out/share/cockpit/zfs
    	cp -r zfs/* $out/share/cockpit/zfs
  '';

  meta = with lib; {
    description = "Cockpit UI for managing ZFS";
    license = licenses.lgpl3Only;
    homepage = "https://github.com/leroycep/cockpit-zfs-manager";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

