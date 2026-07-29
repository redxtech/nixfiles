{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.kagi-mcp = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "kagi-mcp";
        version = "1.0.6";

        src = pkgs.fetchgit {
          url = "https://github.com/kdcokenny/kagi-rs";
          rev = "mcp-v${finalAttrs.version}";
          hash = "sha256-Yg5Ppom/dH+WB5Ced2PGuFp0O1FPnSkZgLPAn+9vje4=";
        };

        cargoHash = "sha256-VO7XZoiVn76lpIXSVBu0ilyxj9RzOapthOCvTdkbeNE=";

        cargoBuildFlags = [
          "--package"
          finalAttrs.pname
        ];
        cargoTestFlags = [
          "--package"
          finalAttrs.pname
        ];

        passthru.updateScript = pkgs.nix-update-script {
          extraArgs = [ "--version-regex=mcp-v(.*)" ];
        };

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
