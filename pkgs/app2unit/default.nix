{ lib, stdenv, fetchFromGitHub, coreutils, xdg-terminal-exec, libnotify }:

stdenv.mkDerivation {
  pname = "app2unit";
  version = "2025-03-18";

  src = fetchFromGitHub {
    owner = "Vladimir-csp";
    repo = "app2unit";
    rev = "b9c13a696f5af7518550cad8184fe817650f520d";
    hash = "sha256-Xv2+yKBvl88wAP256R4GGCaeIQzn70MXDJAi0UzSxx8=";
  };

  buildInputs = [ coreutils xdg-terminal-exec libnotify ];

  installPhase = ''
    mkdir -p $out/bin
    cp app2unit $out/bin
  '';

  meta = {
    description = "A simple app launcher for X11 and Wayland";
    homepage = "https://github.com/Vladimir-csp/app2unit";
    mainProgram = "app2unit";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
