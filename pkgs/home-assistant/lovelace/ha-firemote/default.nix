{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "ha-firemote";
  version = "4.0.5";

  src = fetchFromGitHub {
    owner = "PRProd";
    repo = "HA-Firemote";
    rev = "v${version}";
    hash = "sha256-pytFgzlDXb2rjRVo5p57cpNwmnK2CYrk0tp683kMZRs=";
  };

  installPhase = ''
    runHook preInstall

    cp -r dist/ $out/

    runHook postInstall
  '';

  passthru.entrypoint = "HA-Firemote.js";

  meta = with lib; {
    changelog =
      "https://github.com/PRProd/HA-Firemote/releases/tag/v${version}";
    description =
      "Apple TV, Amazon Fire TV, Fire streaming stick, Chromecast, NVIDIA Shield, onn., Roku, Xiaomi Mi, and Android TV remote control card for Home Assistant";
    homepage = "https://github.com/PRProd/HA-Firemote";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.gpl3Plus;
  };
}
