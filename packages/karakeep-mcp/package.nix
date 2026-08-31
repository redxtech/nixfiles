{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.karakeep-mcp =
        let
          inherit (pkgs)
            fetchurl
            makeWrapper
            nodejs
            stdenvNoCC
            ;
        in
        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "karakeep-mcp";
          version = "0.33.1";

          src = fetchurl {
            url = "https://registry.npmjs.org/@karakeep/mcp/-/mcp-${finalAttrs.version}.tgz";
            hash = "sha256-7gTmY0ZHp++li3iKgA42xIWvuy23fgqUSDeZNqyZZL0=";
          };

          nativeBuildInputs = [ makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin

            install -Dm644 package.json $out/lib/karakeep-mcp/package.json
            install -Dm755 dist/index.js $out/lib/karakeep-mcp/dist/index.js
            makeWrapper ${lib.getExe nodejs} $out/bin/karakeep-mcp \
              --add-flags "$out/lib/karakeep-mcp/dist/index.js"

            runHook postInstall
          '';

          passthru.updateScript = packageUpdateScripts.npm;

          meta = {
            description = "MCP server for Karakeep";
            homepage = "https://github.com/karakeep-app/karakeep/tree/main/apps/mcp";
            license = lib.licenses.agpl3Only;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "karakeep-mcp";
            platforms = nodejs.meta.platforms;
          };
        });
    };
}
