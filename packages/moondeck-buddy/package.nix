{
  perSystem =
    {
      pkgs,
      packageUpdateScripts,
      ...
    }:
    {
      packages.moondeck-buddy =
        let
          pname = "moondeck-buddy";
          version = "1.11.0";

          inherit (pkgs)
            lib
            stdenv
            fetchFromGitHub

            pkg-config
            kdePackages
            cmake
            ninja
            qt6
            procps
            libxrandr
            ;

          inherit (kdePackages) qtbase wrapQtAppsHook;
          qtEnv =
            with qt6;
            env "qt-env-custom-${qtbase.version}" [
              qthttpserver
              qtwebsockets
            ];
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "FrogTheFrog";
            repo = pname;
            tag = "v${version}";
            fetchSubmodules = true;
            hash = "sha256-/zS1Rl8slZndQaEK8TN/rBg9STsMjsUIzS9ci72cBCk=";
          };

          buildInputs = [
            cmake
            ninja
            procps
            libxrandr
            qtbase
            qtEnv
          ];
          nativeBuildInputs = [
            pkg-config
            wrapQtAppsHook
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE:STRING=Release"
            "-G"
            "Ninja"
          ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

          meta = {
            mainProgram = "MoonDeckBuddy";
            description = "Helper to work with moonlight on a steamdeck";
            homepage = "https://github.com/FrogTheFrog/${pname}";
            changelog = "https://github.com/FrogTheFrog/${pname}/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ redxtech ];
            platforms = [ "x86_64-linux" ];
          };
        };
    };
}
