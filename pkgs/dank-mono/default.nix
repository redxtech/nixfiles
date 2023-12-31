{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "dank-mono";
  version = "2020-10-15";

  src = ./dank-mono;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 -t $out/share/fonts/opentype/ $src/*.otf

    runHook postInstall
  '';

  meta = with lib; {
    description = "Dank Mono is a programming font with ligatures.";
    homepage = "https://philpl.gumroad.com/l/dank-mono";
    # license = licenses.unfree;
    platforms = platforms.all;
    maintainers = [ maintainers.redxtech ];
  };
}
