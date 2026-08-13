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
          version = "0.21.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
            hash = "sha256-DV6HS0z6DegRd5Pei+9Zm0euzn3xhkgrgNqcUZT0hhk=";
          };

          npmDepsHash = "sha256-fAdQSxmaDGlW4KRPKCRPKF7eO3sC78PmNUoZ6yxivmY=";

          # The published tarball has no lockfile. These local manifests pin its
          # runtime-only dependency closure and take their release version here.
          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
            substituteInPlace package.json package-lock.json \
              --replace-fail '"version": "0.0.0"' '"version": "${version}"'
          '';

          dontNpmBuild = true;

          passthru.updateScript = packageUpdateScripts.npm;

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
