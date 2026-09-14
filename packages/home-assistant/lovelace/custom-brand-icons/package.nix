{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-lovelace-custom-brand-icons =
        let
          inherit (pkgs)
            stdenv
            fetchFromGitHub
            ;
        in
        stdenv.mkDerivation rec {
          pname = "custom-brand-icons";
          version = "2026.09.0";

          src = fetchFromGitHub {
            owner = "elax46";
            repo = "custom-brand-icons";
            rev = "${version}";
            hash = "sha256-khX+OqeAN45kFAhMOOq3k4N/FtkS//p+1LaskDL3so8=";
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
            changelog = "https://github.com/elax46/custom-brand-icons/releases/tag/${version}";
            description = "Custom brand icons for Home Assistant";
            homepage = "https://github.com/elax46/custom-brand-icons";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.gpl3Plus;
          };
        };
    };
}
