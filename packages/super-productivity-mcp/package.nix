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
          version = "1.7.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "b0x42";
            repo = "Super-Productivity-MCP";
            rev = "v${version}";
            hash = "sha256-PpgDSCL/877sNIDDDM3Ob7OGumIRLzJmWU9HHHpezEE=";
          };

          npmDepsHash = "sha256-bW/zGS26HMsJb83QGYZ4OBHDBz4j8SaSf+lP89k4ikI=";

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
