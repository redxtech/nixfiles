{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.pi-acp =
        let
          inherit (pkgs) buildNpmPackage fetchFromGitHub;

          pname = "pi-acp";
          version = "0.0.33";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "svkozak";
            repo = pname;
            tag = "v${version}";
            hash = "sha256-fENOOdooi4XbIDjcr02q8qzUCzdo2IW/Bca43SawZ44=";
          };

          npmDepsHash = "sha256-/fX79XucKojL/6gZbK5eizEfrXso8rlTgiHfJffmDuY=";

          passthru.updateScript = packageUpdateScripts.githubRelease;

          meta = {
            description = "ACP adapter for the pi coding agent";
            homepage = "https://github.com/svkozak/pi-acp";
            changelog = "https://github.com/svkozak/pi-acp/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "pi-acp";
            platforms = lib.platforms.unix;
          };
        };
    };
}
