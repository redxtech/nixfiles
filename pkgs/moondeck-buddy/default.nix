{ lib, stdenv, fetchFromGitHub, pkg-config, wrapQtAppsHook, qtbase, cmake, qt6
, procps, xorg }:

let
  pname = "moondeck-buddy";
  version = "1.6.3";

  qtEnv = with qt6;
    env "qt-env-custom-moondeck-buddy-${qtbase.version}" [
      qthttpserver
      qtwebsockets
    ];
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "FrogTheFrog";
    repo = pname;
    tag = "v${version}";
    hash = "sha256-U5Q/NQitOVTgaGtfckss7Bpn9hvIRFMSAZ9Uh+hVIic=";
  };

  buildInputs = [ cmake procps xorg.libXrandr qtbase qtEnv ];
  nativeBuildInputs = [ pkg-config wrapQtAppsHook ];

  preConfigure = let
    ssl-deps = fetchFromGitHub {
      owner = "FrogTheFrog";
      repo = "moondeck-keys";
      rev = "9d1cc7356181f6f6c0aa2a5e92ad7174f09fa539";
      hash = "sha256-nvGNjxK878tx5fUGt8ACYeVcqs6KbKATXlwMe6ghS0A=";
    };
  in ''
    mkdir -p resources/ssl
    cp ${ssl-deps}/*.pem resources/ssl
  '';

  meta = with lib; {
    description = "Helper to work with moonlight on a steamdeck";
    homepage = "https://github.com/FrogTheFrog/moondeck-buddy";
    changelog =
      "https://github.com/FrogTheFrog/${pname}/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
