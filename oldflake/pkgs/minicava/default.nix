{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  cava,
  gnused,
  nix-update-script,
}:

with lib;

stdenv.mkDerivation {
  pname = "minicava";
  version = "0-unstable-2023-01-28";
  src = fetchFromGitHub {
    owner = "Misterio77";
    repo = "minicava";
    rev = "c24681fe7c91548e0fb4f55a1882b0145c48d097";
    sha256 = "sha256-t+NHZP2I7clDHrnCDdYMaLcua7inVKm2t3aYZ3uBAlk=";
  };

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dm 0755 minicava.sh $out/bin/minicava
    wrapProgram $out/bin/minicava --set PATH \
      "${
        makeBinPath [
          cava
          gnused
        ]
      }"
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "A miniature cava sound visualizer";
    homepage = "https://github.com/Misterio77/minicava";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
