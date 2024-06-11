{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "dank-mono";
  version = "2020-10-15";

  src = ./dank-mono;

  installPhase = ''
    install -D -m 444 $src/*.ttf -t $out/share/fonts/ttf
  '';

  meta = with lib; {
    description = "Dank Mono is a programming font with ligatures.";
    homepage = "https://philpl.gumroad.com/l/dank-mono";
    # license = licenses.unfree;
    platforms = platforms.all;
    maintainers = [ maintainers.redxtech ];
  };
}
