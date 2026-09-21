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
          version = "0.23.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
            hash = "sha256-VZTWOeUIj4uuizsrmMs+gGwYj+m2rf4ucY+CAodB8f0=";
          };

          npmDepsHash = "sha256-0bAcS2dcOy64yOy5U6FwXZps6+wTJ1xn1EBxJ3D7DnY=";

          # The published tarball has no lockfile. These local manifests pin its
          # runtime-only dependency closure and take their release version here.
          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
            substituteInPlace package.json package-lock.json \
              --replace-fail '"version": "0.0.0"' '"version": "${version}"'
          '';

          dontNpmBuild = true;
          doInstallCheck = true;
          installCheckPhase = ''
            runHook preInstallCheck
            $out/bin/gws-axi --help > /dev/null
            runHook postInstallCheck
          '';

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
