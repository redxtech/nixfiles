{ lib, stdenv, fetchFromGitHub, nix-update-script, pkg-config, kdePackages
, cmake, ninja, qt6, procps, xorg, }:

let
  pname = "moondeck-buddy";
  version = "1.7.1";

  inherit (kdePackages) qtbase wrapQtAppsHook;
  qtEnv = with qt6;
    env "qt-env-custom-${qtbase.version}" [ qthttpserver qtwebsockets ];
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "FrogTheFrog";
    repo = pname;
    tag = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-7lMtywWVTH+ZJO7BDG9PgN/phyob7so9/h6ShK6Ml04=";
  };

  buildInputs = [ cmake ninja procps xorg.libXrandr qtbase qtEnv ];
  nativeBuildInputs = [ pkg-config wrapQtAppsHook ];

  cmakeFlags = [ "-DCMAKE_BUILD_TYPE:STRING=Release" "-G" "Ninja" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "MoonDeckBuddy";
    description = "Helper to work with moonlight on a steamdeck";
    homepage = "https://github.com/FrogTheFrog/${pname}";
    changelog =
      "https://github.com/FrogTheFrog/${pname}/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
