{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.strava-mcp = pkgs.buildNpmPackage (finalAttrs: {
        pname = "strava-mcp";
        version = "1.2.1";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@r-huijts/strava-mcp-server/-/strava-mcp-server-${finalAttrs.version}.tgz";
          hash = "sha256-r0ZTAVHyzXwULMSJBpUpb+eJ5PbZ/HoGcIriBQCEpmA=";
        };

        npmDepsHash = "sha256-HFoxTbNfaRX22AYlScL5TFRADvvVZGVvfStXfeSe/+A=";
        postPatch = ''
          cp ${./npm-package.json} package.json
          cp ${./npm-package-lock.json} package-lock.json
        '';
        dontNpmBuild = true;

        passthru.updateScript = packageUpdateScripts.npm;

        meta = {
          description = "MCP server for the Strava API";
          homepage = "https://github.com/r-huijts/strava-mcp";
          license = lib.licenses.isc;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "strava-mcp-server";
          platforms = pkgs.nodejs.meta.platforms;
        };
      });
    };
}
