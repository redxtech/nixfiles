{
  lib,
  stdenv,
  fetchFromGitHub,
  curl,
  gh,
  unzip,
  p7zip,
  nix-update-script,
}:

stdenv.mkDerivation rec {
  pname = "switchup";
  version = "nightly-unstable-2024-03-02";
  src = fetchFromGitHub {
    owner = "redxtech";
    repo = "switchup";
    rev = "c064674b280b341eb3d7b9f4b76b12bd89f81d02";
    hash = "sha256-A5bOwoQJE1GAcCKyweVb4rjkWJ2d8T4JI/+WT4Empnw=";
  };

  propagatedBuildInputs = [
    curl
    gh
    unzip
    p7zip
  ];

  installPhase = ''
    install -dm 755 $out/bin
    install -dm 755 $out/share

    cp --no-preserve='ownership' ${src}/bin/switchup $out/bin
    cp -r --no-preserve='ownership' ${src}/share/switchup $out/share
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta = with lib; {
    description = "Script to create an SD card for a modded Nintendo Switch";
    homepage = "https://github.com/redxtech/switchup";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ redxtech ];
  };
}
