{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "custom-brand-icons";
  version = "2024.9.1";

  src = fetchFromGitHub {
    owner = "elax46";
    repo = "custom-brand-icons";
    rev = "${version}";
    hash = "sha256-ZQFhM75aKniboOR1H3xEjZCx1JVPSkz8omEx+FSDFdA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp dist/*.js $out/

    runHook postInstall
  '';

  meta = with lib; {
    changelog =
      "https://github.com/elax46/custom-brand-icons/releases/tag/${version}";
    description = "Custom brand icons for Home Assistant";
    homepage = "https://github.com/elax46/custom-brand-icons";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.gpl3Plus;
  };
}
