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
          version = "0.2.5";

          src = fetchFromGitHub {
            owner = "papra-hq";
            repo = "papra";
            tag = "@papra/cli@${version}";
            hash = "sha256-3VD/bzEwgh1mBXwwOsz8gq7NqUOV7I4rc+tziFuI1uc=";
          };
        in
        stdenvNoCC.mkDerivation {
          inherit pname version src;

          pnpmDeps = fetchPnpmDeps {
            inherit pname version src;
            fetcherVersion = 4;
            hash = "sha256-I0eCsWmpKFKJYz9kunMhKlI3co6z10e97Km4Q4emJO0=";
            pnpmWorkspaces = [ "@papra/cli..." ];
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
            pnpm deploy --ignore-script --filter=@papra/cli --prod $out/lib/papra-cli
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
