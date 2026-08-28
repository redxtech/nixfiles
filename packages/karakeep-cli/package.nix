{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.karakeep-cli =
        let
          inherit (pkgs)
            fetchurl
            makeWrapper
            nodejs
            stdenvNoCC
            ;
        in
        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "karakeep-cli";
          version = "0.33.1";

          src = fetchurl {
            url = "https://registry.npmjs.org/@karakeep/cli/-/cli-${finalAttrs.version}.tgz";
            hash = "sha256-L+yvZimSO9wmqYpavx6KbYZkMsOgjdU9408CDHVHLFM=";
          };

          nativeBuildInputs = [ makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin

            install -Dm755 dist/index.mjs $out/lib/karakeep-cli/dist/index.mjs
            makeWrapper ${lib.getExe nodejs} $out/bin/karakeep \
              --add-flags "$out/lib/karakeep-cli/dist/index.mjs"

            runHook postInstall
          '';

          passthru.updateScript = packageUpdateScripts.npm;

          meta = {
            description = "Command-line interface for Karakeep";
            homepage = "https://github.com/karakeep-app/karakeep/tree/main/apps/cli";
            changelog = "https://github.com/karakeep-app/karakeep/releases/tag/v${finalAttrs.version}";
            license = lib.licenses.agpl3Only;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "karakeep";
            platforms = nodejs.meta.platforms;
          };
        });
    };
}
