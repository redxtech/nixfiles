{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.kimaki =
        let
          inherit (pkgs)
            buildNpmPackage
            bun
            fetchurl
            makeWrapper
            which
            ;

          pname = "kimaki";
          version = "0.25.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/kimaki/-/kimaki-${version}.tgz";
            hash = "sha256-uev/5eR/EBi3azOU+UcXONSZD2QZ3aMMQzvxVw4iqjY=";
          };

          npmDepsHash = "sha256-cCYF4MlCP7k7UL3Dh8x/3dgU3T3YsScxBD5W1kVFVu0=";

          nativeBuildInputs = [ makeWrapper ];

          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
          '';

          dontNpmBuild = true;

          postFixup = ''
            wrapProgram $out/bin/kimaki \
              --prefix PATH : ${
                lib.makeBinPath [
                  bun
                  which
                ]
              }
          '';

          passthru.updateScript = packageUpdateScripts.npm;

          meta = {
            description = "Collaborative agent orchestrator inside Discord";
            homepage = "https://github.com/remorses/kimaki";
            changelog = "https://github.com/remorses/kimaki/releases/tag/kimaki%40${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "kimaki";
            platforms = lib.platforms.linux;
          };
        };
    };
}
