{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.strava-mcp =
        let
          pname = "strava-mcp";
          version = "1.2.1";
        in
        pkgs.buildNpmPackage {
          inherit pname version;

          src = pkgs.fetchFromGitHub {
            owner = "r-huijts";
            repo = "strava-mcp";
            rev = "ac43cc7b0aad2f218b9c42bd639aee696dbee531";
            hash = "sha256-Hj1cS7xcbYAPocNWxvvpLsHlWVz3QyV3TArlYk3ssng=";
          };

          npmDepsHash = "sha256-CjFgJ3HKfPlX29Bfs2CwdRGqtR3lO2O6sqModJnPCH4=";

          meta = {
            description = "MCP server for the Strava API";
            homepage = "https://github.com/r-huijts/strava-mcp";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "strava-mcp-server";
          };
        };
    };
}
