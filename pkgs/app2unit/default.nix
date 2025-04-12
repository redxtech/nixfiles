{
  lib,
  stdenv,
  fetchFromGitHub,
  coreutils,
  xdg-terminal-exec,
  libnotify,
  nix-update-script,
}:

stdenv.mkDerivation {
  pname = "app2unit";
  version = "0-unstable-2025-04-03";

  src = fetchFromGitHub {
    owner = "Vladimir-csp";
    repo = "app2unit";
    rev = "44b5da8a6f1e5449d3c2a8b63dc54875bb7e10af";
    hash = "sha256-SJVGMES0tmdAhh2u8IpGAITtSnDrgSfOQbDX9RhOc/M=";
  };

  buildInputs = [
    coreutils
    xdg-terminal-exec
    libnotify
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp app2unit $out/bin
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "A simple app launcher for X11 and Wayland";
    homepage = "https://github.com/Vladimir-csp/app2unit";
    mainProgram = "app2unit";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
