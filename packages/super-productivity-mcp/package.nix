{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.super-productivity-mcp =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchFromGitHub
            zip
            ;

          pname = "super-productivity-mcp";
          version = "1.3.5";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "b0x42";
            repo = "Super-Productivity-MCP";
            rev = "v${version}";
            hash = "sha256-E/0+9RyqdHJPOUHKf2j/ijrKTTZ1J22MmkcHCizf3L4=";
          };

          npmDepsHash = "sha256-hellP4Y+Ur6RxsDSbC+YVRiCMjqwN++mzcgr4DhXdz8=";

          nativeBuildInputs = [ zip ];

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
