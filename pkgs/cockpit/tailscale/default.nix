{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "cockpit-tailscale";
  version = "0.0.6";

  src = fetchzip {
    url =
      "https://github.com/spotsnel/cockpit-tailscale/releases/download/v${version}/cockpit-tailscale-v${version}.tar.gz";
    sha256 = "sha256-ESUZdt8GVEToyrv6UP8lOff67LsumdJAY1lXvC3fBaI=";
  };

  installPhase = ''
    mkdir -p $out/share/cockpit
    cp -r ${src} $out/share/cockpit/tailscale
  '';

  meta = with lib; {
    description = "Cockpit UI for tailscale";
    license = licenses.lgpl21;
    homepage = "https://github.com/spotsnel/cockpit-tailscale";
    platforms = platforms.linux;
    maintainers = with maintainers; [ redxtech ];
  };
}

