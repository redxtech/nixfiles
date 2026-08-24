{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.super-productivity-mcp =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchFromGitHub
            zip
            ;

          pname = "super-productivity-mcp";
          version = "1.5.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "b0x42";
            repo = "Super-Productivity-MCP";
            rev = "v${version}";
            hash = "sha256-jQ/ZNWwWpDTfNyy75vBqr1p8XwSUuROEZCzR7njCSig=";
          };

          npmDepsHash = "sha256-LHwA0eXOtB5t1PaALq7mcXx1B6nmznd8Q2CZu/zlnkQ=";

          nativeBuildInputs = [ zip ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

          meta = {
            description = "MCP server for managing Super Productivity through AI assistants";
            homepage = "https://github.com/b0x42/Super-Productivity-MCP";
            changelog = "https://github.com/b0x42/Super-Productivity-MCP/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "super-productivity-mcp";
          };
        };
    };
}
