{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.gws-axi =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchurl
            nodejs
            ;

          pname = "gws-axi";
          version = "0.37.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
            hash = "sha256-+tqZIfZSRAvx2PSswBjFeQKZ5pSWR7d+gpQ09QUWsUA=";
          };

          npmDepsHash = "sha256-0WibX1lAfFycbihiRBpOPRJei+97jVUlEd+fzcqs0kA=";
          npmDepsFetcherVersion = 2;

          # keep the runtime manifest and lockfile from the same published release
          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
          '';

          npmRebuildFlags = [ "--ignore-scripts" ];
          dontNpmBuild = true;
          doInstallCheck = true;
          installCheckPhase = ''
            runHook preInstallCheck
            $out/bin/gws-axi --help > /dev/null
            runHook postInstallCheck
          '';

          passthru.updateScript = packageUpdateScripts.npmWithLockfile pname;

          meta = {
            description = "Agent-ergonomic CLI for Google Workspace";
            homepage = "https://github.com/JarvusInnovations/${pname}";
            changelog = "https://github.com/JarvusInnovations/${pname}/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = pname;
            platforms = nodejs.meta.platforms;
          };
        };
    };
}
