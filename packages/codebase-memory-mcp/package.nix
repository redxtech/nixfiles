{ ... }:
let
  version = "0.10.8";
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
      pkgs,
      ...
    }:
    let
      updateScript = pkgs.writeShellApplication {
        name = "update-codebase-memory-mcp";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          python3
        ];
        text = ''
          packageFile=packages/codebase-memory-mcp/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/DeusData/codebase-memory-mcp/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"

          python3 - "$packageFile" "$version" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version = sys.argv[2]
          text = path.read_text()
          text, replacements = re.subn(
              r'(?m)^(  version = ")[^"]+(";)$',
              rf'\g<1>{version}\g<2>',
              text,
              count=1,
          )
          if replacements != 1:
              raise SystemExit(f"expected one version in {path}, replaced {replacements}")
          path.write_text(text)
          PY

          nix run .#write-flake
          nix flake update codebase-memory-mcp
        '';
      };
    in
    {
      packages.codebase-memory-mcp =
        inputs'.codebase-memory-mcp.packages.default.overrideAttrs
          (oldAttrs: {
            inherit version;
            __intentionallyOverridingVersion = true;
            CFLAGS_EXTRA = ''-DCBM_VERSION=\"${version}\"'';
            passthru = (oldAttrs.passthru or { }) // {
              updateScript = lib.getExe updateScript;
            };
            meta = oldAttrs.meta // {
              changelog = "https://github.com/DeusData/codebase-memory-mcp/releases/tag/v${version}";
              mainProgram = "codebase-memory-mcp";
              maintainers = [ lib.maintainers.redxtech ];
            };
          });
    };
}
