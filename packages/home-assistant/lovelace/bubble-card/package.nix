{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-lovelace-bubble-card =
        let
          inherit (pkgs)
            stdenv
            fetchFromGitHub
            ;
        in
        stdenv.mkDerivation rec {
          pname = "bubble-card";
          version = "3.3.0";

          src = fetchFromGitHub {
            owner = "Clooos";
            repo = "Bubble-Card";
            rev = "v${version}";
            hash = "sha256-UmGqduu1k5nF0N+3WruSJ172Hu2UwVgMkTKTtSygQQ0=";
          };

          passthru.updateScript = packageUpdateScripts.githubRelease;

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir $out
            cp dist/*.js $out/

            runHook postInstall
          '';

          meta = with lib; {
            changelog = "https://github.com/Clooos/Bubble-Card/releases/tag/v${version}";
            description = "Bubble Card is a minimalist card collection for Home Assistant with a nice pop-up touch.";
            homepage = "https://github.com/Clooos/Bubble-Card";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.gpl3Plus;
          };
        };
    };
}
