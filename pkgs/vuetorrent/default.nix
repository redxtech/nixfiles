{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "vuetorrent";
  version = "2.18.0";

  src = fetchzip {
    url =
      "https://github.com/VueTorrent/VueTorrent/releases/download/v${version}/vuetorrent.zip";
    hash = "sha256-Z+N1RgcF67R6hWEfmfBls1+YLWkhEJQuOVqXXJCyptE=";
  };

  installPhase = ''
    mkdir -p $out/var/www/vuetorrent
    cp -r * $out/var/www/vuetorrent
  '';

  meta = {
    description =
      "VueTorrent is a full-featured BitTorrent client written in Vue";
    homepage = "https://github.com/VueTorrent/VueTorrent";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ redxtech ];
  };
}
