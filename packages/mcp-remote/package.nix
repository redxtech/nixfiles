{
  perSystem =
    { pkgs, lib, ... }:
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
            stdenv
            ;

          pname = "mcp-remote";
          version = "0.1.38";

          src = fetchFromGitHub {
            owner = "geelen";
            repo = "mcp-remote";
            rev = "v${version}";
            hash = "sha256-+oNI2Uq7gW3sLzJS4ky2+BXhTmo44+WpcdYgieGPpmI=";
          };

          pnpmDeps = fetchPnpmDeps {
            inherit pname version src;
            fetcherVersion = 3;
            hash = "sha256-1kTJK8uoEKigEBdi/FWE84aUJu+ehyD1j4wuex0y2mU=";
          };
        in
        stdenv.mkDerivation {
          inherit
            pname
            version
            src
            pnpmDeps
            ;

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

            install -d "$out/lib/node_modules/${pname}" "$out/bin"
            cp -r dist node_modules package.json "$out/lib/node_modules/${pname}/"

            makeWrapper ${nodejs}/bin/node "$out/bin/mcp-remote" \
              --add-flags "$out/lib/node_modules/${pname}/dist/proxy.js"
            makeWrapper ${nodejs}/bin/node "$out/bin/mcp-remote-client" \
              --add-flags "$out/lib/node_modules/${pname}/dist/client.js"

            runHook postInstall
          '';

          passthru.updateScript = pkgs.nix-update-script { };

          meta = {
            description = "Connect local-only MCP clients to remote MCP servers";
            homepage = "https://github.com/geelen/mcp-remote";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "mcp-remote";
          };
        };
    };
}
