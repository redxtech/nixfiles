{ ... }:
let
  version = "0.9.0";
in
{
  flake-file.inputs.codebase-memory-mcp = {
    url = "github:DeusData/codebase-memory-mcp/v${version}";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    {
      inputs',
      lib,
      ...
    }:
    {
      packages.codebase-memory-mcp =
        inputs'.codebase-memory-mcp.packages.default.overrideAttrs
          (oldAttrs: {
            inherit version;
            __intentionallyOverridingVersion = true;
            CFLAGS_EXTRA = ''-DCBM_VERSION=\"${version}\"'';
            meta = oldAttrs.meta // {
              changelog = "https://github.com/DeusData/codebase-memory-mcp/releases/tag/v${version}";
              mainProgram = "codebase-memory-mcp";
              maintainers = [ lib.maintainers.redxtech ];
            };
          });
    };
}
