{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.papra-cli =
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

          pname = "papra-cli";
          version = "0.2.6";
          pnpmWorkspaces = [ "@papra/cli..." ];

          src = fetchFromGitHub {
            owner = "papra-hq";
            repo = "papra";
            tag = "@papra/cli@${version}";
            hash = "sha256-LiGEo+aANVJdBnGDuU/2Iir8gSTYHcbCqAHPMnKvg8E=";
          };
        in
        stdenvNoCC.mkDerivation {
          inherit
            pname
            version
            src
            pnpmWorkspaces
            ;

          pnpmDeps = fetchPnpmDeps {
            inherit
              pname
              version
              src
              pnpmWorkspaces
              ;
            fetcherVersion = 4;
            hash = "sha256-oh0OV1Ob4+EJsP2sgvpxFFmTNEyOiduZNz6GbcO69J8=";
          };

          nativeBuildInputs = [
            makeWrapper
            nodejs
            pnpm
            pnpmConfigHook
          ];

          buildPhase = ''
            runHook preBuild
            pnpm --filter "@papra/cli..." run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/{bin,lib/papra-cli}
            pnpm config set --location=project injectWorkspacePackages true
            pnpm deploy --ignore-scripts --filter=@papra/cli --prod $out/lib/papra-cli
            makeWrapper ${lib.getExe nodejs} $out/bin/papra \
              --add-flags "$out/lib/papra-cli/bin/papra.mjs"

            runHook postInstall
          '';

          passthru.updateScript = packageUpdateScripts.githubMatchingTag {
            owner = "papra-hq";
            packageName = pname;
            repo = "papra";
            tagPrefix = "@papra/cli@";
          };

          meta = {
            description = "Command-line interface for the Papra document management platform";
            homepage = "https://docs.papra.app/resources/cli/";
            changelog = "https://github.com/papra-hq/papra/releases/tag/%40papra%2Fcli%40${version}";
            license = lib.licenses.agpl3Plus;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "papra";
            platforms = lib.platforms.unix;
          };
        };
    };
}
