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
          version = "1.4.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "b0x42";
            repo = "Super-Productivity-MCP";
            rev = "v${version}";
            hash = "sha256-wVBGj+OeSVprpwEvyjUWlHAT0sRBlQf5xiFf4DTPQAk=";
          };

          npmDepsHash = "sha256-NaA4lXTYrrh84RyHvyvqC+YmxR575P38Rq+cy8YB49Q=";

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
