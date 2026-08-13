{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.gh-axi =
        let
          inherit (pkgs)
            fetchFromGitHub
            fetchPnpmDeps
            gh
            makeWrapper
            nodejs
            pnpm
            pnpmConfigHook
            stdenvNoCC
            ;

          pname = "gh-axi";
          version = "0.1.29";

          src = fetchFromGitHub {
            owner = "kunchenguid";
            repo = pname;
            tag = "gh-axi-v${version}";
            hash = "sha256-xGabDo12fh+YO1ihSo6fyh8bYiELH+iWRDPZ37dMzNI=";
          };
        in
        stdenvNoCC.mkDerivation {
          inherit pname version src;

          pnpmDeps = fetchPnpmDeps {
            inherit pname version src;
            fetcherVersion = 4;
            hash = "sha256-snoKB2/sZmuvqFtmUAVPcyL6hcGX7+EGRN+49wwPX1o=";
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

            mkdir -p $out/lib/gh-axi $out/bin
            cp -r dist node_modules package.json skills $out/lib/gh-axi/
            makeWrapper ${lib.getExe nodejs} $out/bin/gh-axi \
              --add-flags "$out/lib/gh-axi/dist/bin/gh-axi.js" \
              --prefix PATH : ${lib.makeBinPath [ gh ]}

            runHook postInstall
          '';

          passthru.updateScript = packageUpdateScripts.githubReleaseWithRegex "gh-axi-v(.*)";

          meta = {
            description = "GitHub CLI wrapper optimized for autonomous agents";
            homepage = "https://github.com/kunchenguid/gh-axi";
            changelog = "https://github.com/kunchenguid/gh-axi/releases/tag/gh-axi-v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "gh-axi";
            platforms = lib.platforms.unix;
          };
        };
    };
}
