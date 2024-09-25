{ lib, stdenv, fetchzip, ... }:

stdenv.mkDerivation rec {
  pname = "ente-cli";
  version = "0.2.1";

  src = fetchzip {
    url =
      "https://github.com/ente-io/ente/releases/download/cli-v${version}/ente-cli-v${version}-linux-arm64.tar.gz";
    hash = "sha256-GzHbHrzCMNdvfWjbELORfX9LPGax+l0UKPIeSiPKDBA=";
  };

  installPhase = ''
    mkdir -p $out/bin
    ln -s $src/ente $out/bin/ente
  '';

  meta = with lib; {
    description =
      "The Ente CLI is a Command Line Utility for exporting data from Ente.";
    homepage = "https://github.com/ente-io/ente/tree/main/cli";
    changelog = "https://github.com/ente-io/ente/releases/tag/cli-v${version}";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
