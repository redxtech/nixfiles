{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.mcp-remote =
        let
          inherit (pkgs)
            fetchFromGitHub
            fetchPnpmDeps
            makeWrapper
            nodejs
            pnpm
            pnpmConfigHook
            stdenvNoCC
            ;

          pname = "mcp-remote";
          version = "0.8.3";

          src = fetchFromGitHub {
            owner = "geelen";
            repo = "mcp-remote";
            rev = "v${version}";
            hash = "sha256-pnCHGSZRuv67LmnvzVDJZHRpSyiaoY1mNX5mJyZ/2AA=";
          };
        in
        stdenvNoCC.mkDerivation {
          inherit pname version src;

          pnpmDeps = fetchPnpmDeps {
            inherit pname version src;
            fetcherVersion = 4;
            hash = "sha256-IebPx63WhlZTIDlccuISxdo9jpzXQ609DKwir2adMl0=";
          };

          nativeBuildInputs = [
            makeWrapper
            nodejs
            pnpm
            pnpmConfigHook
          ];

          buildPhase = ''
            runHook preBuild
            pnpm build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/mcp-remote $out/bin
            cp -r dist node_modules package.json $out/lib/mcp-remote/

            makeWrapper ${lib.getExe nodejs} $out/bin/mcp-remote \
              --add-flags "$out/lib/mcp-remote/dist/proxy.js"
            makeWrapper ${lib.getExe nodejs} $out/bin/mcp-remote-client \
              --add-flags "$out/lib/mcp-remote/dist/client.js"

            runHook postInstall
          '';

          # Upstream publishes stable version tags without GitHub Release objects.
          passthru.updateScript = packageUpdateScripts.githubTag;

          meta = {
            description = "Remote proxy for Model Context Protocol clients";
            homepage = "https://github.com/geelen/mcp-remote";
            changelog = "https://github.com/geelen/mcp-remote/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "mcp-remote";
          };
        };
    };
}
