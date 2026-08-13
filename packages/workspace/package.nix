{ inputs, ... }:

{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (inputs)
        pyproject-build-systems
        pyproject-nix
        uv2nix
        ;
      inherit (pkgs)
        fetchFromGitHub
        makeWrapper
        python313
        ;

      version = "1.23.0";
      src = fetchFromGitHub {
        owner = "taylorwilsdon";
        repo = "google_workspace_mcp";
        tag = "v${version}";
        hash = "sha256-eQXUMCSveNQZQ5InTlz6hENIW89Ok/RgC58nQb7uO1I=";
      };
      updateScript = pkgs.writeShellApplication {
        name = "update-workspace-mcp";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          python3
        ];
        text = ''
          packageFile=packages/workspace/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/taylorwilsdon/google_workspace_mcp/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"
          sourceHash="$(
            nix store prefetch-file --unpack --json \
              "https://github.com/taylorwilsdon/google_workspace_mcp/archive/refs/tags/$tag.tar.gz" \
              | jq --exit-status --raw-output .hash
          )"

          python3 - "$packageFile" "$version" "$sourceHash" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version, source_hash = sys.argv[2:]
          text = path.read_text()
          text, version_replacements = re.subn(
              r'(?m)^(      version = ")[^"]+(";)$',
              rf'\g<1>{version}\g<2>',
              text,
              count=1,
          )
          text, hash_replacements = re.subn(
              r'(?m)^(        hash = ")[^"]+(";)$',
              rf'\g<1>{source_hash}\g<2>',
              text,
              count=1,
          )
          if (version_replacements, hash_replacements) != (1, 1):
              raise SystemExit(
                  f"unexpected replacements in {path}: "
                  f"version={version_replacements}, source hash={hash_replacements}"
              )
          path.write_text(text)
          PY
        '';
      };

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      workspaceOverlay = _final: prev: {
        workspace-mcp = prev.workspace-mcp.overrideAttrs (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace main.py \
              --replace-fail \
                'argparse.ArgumentParser(description="Google Workspace MCP Server")' \
                'argparse.ArgumentParser(prog="workspace-mcp", description="Google Workspace MCP Server")'
          '';
        });
      };
      pythonSet = (pkgs.callPackage pyproject-nix.build.packages { python = python313; }).overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
          workspaceOverlay
        ]
      );

      workspaceEnv =
        (pythonSet.mkVirtualEnv "workspace-mcp-${version}" workspace.deps.default).overrideAttrs
          (oldAttrs: {
            nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ makeWrapper ];
            postFixup = ''
              wrapProgram $out/bin/workspace-mcp --unset PYTHONPATH
              wrapProgram $out/bin/workspace-cli --argv0 workspace-cli --unset PYTHONPATH
            '';

          });
      workspace-mcp =
        pkgs.runCommand "workspace-mcp-${version}"
          {
            passthru.updateScript = lib.getExe updateScript;
            meta = {
              description = "Google Workspace MCP server and CLI";
              homepage = "https://github.com/taylorwilsdon/google_workspace_mcp";
              changelog = "https://github.com/taylorwilsdon/google_workspace_mcp/releases/tag/v${version}";
              license = lib.licenses.mit;
              maintainers = with lib.maintainers; [ redxtech ];
              mainProgram = "workspace-mcp";
            };
          }
          ''
            mkdir -p $out/bin
            ln -s ${workspaceEnv}/bin/workspace-mcp $out/bin/workspace-mcp
            ln -s ${workspaceEnv}/bin/workspace-cli $out/bin/workspace-cli
          '';
    in
    {
      packages = { inherit workspace-mcp; };

      apps.workspace-cli = {
        type = "app";
        program = lib.getExe' workspace-mcp "workspace-cli";
        meta.description = "run workspace-cli";
      };
    };

  flake-file.inputs = {
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };
  };
}
