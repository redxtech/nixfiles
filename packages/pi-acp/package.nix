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
          version = "0.0.34";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "svkozak";
            repo = pname;
            tag = "v${version}";
            hash = "sha256-QRwxOtTZOY+Np3PkAoy2o2PrUzEqjItM/372sCPlSMo=";
          };

          npmDepsHash = "sha256-BvLNtFfp1cMVjzWcMRSdhTqiJrTfbFoUbWkkPW9200o=";

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
