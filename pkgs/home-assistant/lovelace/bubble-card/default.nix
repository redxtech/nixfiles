{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "bubble-card";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "Clooos";
    repo = "Bubble-Card";
    rev = "v${version}";
    hash = "sha256-vsgu1hvtlppADvaFLeB4xQHbP3wBc6H4p5HbeS3JY80=";
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
      "https://github.com/Clooos/Bubble-Card/releases/tag/v${version}";
    description =
      "Bubble Card is a minimalist card collection for Home Assistant with a nice pop-up touch.";
    homepage = "https://github.com/Clooos/Bubble-Card";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.gpl3Plus;
  };
}
