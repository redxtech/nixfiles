{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "waze-travel-time";
  version = "2020-05-15";

  src = fetchFromGitHub {
    owner = "r-renato";
    repo = "ha-card-waze-travel-time";
    rev = "038f2a836f9e002416e8d0fb674de932d1072c3c";
    hash = "sha256-7yyuWKtDQ/vM53S3p1TvLgAJe7w1xrVUoHNBkjHtX+I=";
  };

  installPhase = ''
    runHook preInstall

    cp -r dist/ $out/

    runHook postInstall
  '';

  passthru.entrypoint = "ha-card-${pname}.js";

  meta = with lib; {
    changelog =
      "https://github.com/r-renato/ha-card-waze-travel-time/commits/master";
    description = "Home Assistant Lovelace card for Waze Travel Time Sensor";
    homepage = "https://github.com/r-renato/ha-card-waze-travel-time";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
