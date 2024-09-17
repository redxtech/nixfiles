{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "lovelace-horizon-card";
  owner = "rejuvenate";
  version = "1.1.0";

  src = fetchurl {
    url =
      "https://github.com/${owner}/${pname}/releases/download/v${version}/${pname}.js";
    hash = "sha256-tOB3/UJNDTQQKS7/2Ned6Ke8t88cAL13RzO+llChLgw=";
  };

  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp ${src} $out/${pname}.js

    runHook postInstall
  '';

  meta = with lib; {
    changelog =
      "https://github.com/rejuvenate/lovelace-horizon-card/releases/tag/v${version}";
    description =
      "Sun Card successor: Visualize the position of the Sun over the horizon.";
    homepage = "https://github.com/rejuvenate/lovelace-horizon-card";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
