{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.kagi-mcp = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "kagi-mcp";
        version = "1.0.7";

        src = pkgs.fetchgit {
          url = "https://github.com/kdcokenny/kagi-rs";
          rev = "mcp-v${finalAttrs.version}";
          hash = "sha256-IkkOjr7bZ3/xLlXkT2cgncW3dO6bZJeObIjvw2b4A2Y=";
        };

        cargoHash = "sha256-4/viwL2OBSnaSKFZB9Mgct7n83XL0WuoEaYSFze/dKQ=";

        cargoBuildFlags = [
          "--package"
          finalAttrs.pname
        ];
        cargoTestFlags = [
          "--package"
          finalAttrs.pname
        ];

        passthru.updateScript = packageUpdateScripts.githubReleaseWithRegex "mcp-v(.*)";

        meta = {
          description = "MCP server for Kagi search and summarization";
          homepage = "https://github.com/kdcokenny/kagi-rs";
          changelog = "https://github.com/kdcokenny/kagi-rs/releases/tag/mcp-v${finalAttrs.version}";
          license = lib.licenses.mit;
          mainProgram = "kagi-mcp";
          maintainers = [ lib.maintainers.redxtech ];
          platforms = lib.platforms.unix;
        };
      });
    };
}
