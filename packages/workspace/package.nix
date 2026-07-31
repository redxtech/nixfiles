{ inputs, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
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

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      pythonSet = (pkgs.callPackage pyproject-nix.build.packages { python = python313; }).overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
        ]
      );

      workspaceEnv =
        (pythonSet.mkVirtualEnv "workspace-mcp-${version}" workspace.deps.default).overrideAttrs
          (oldAttrs: {
            nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ makeWrapper ];
            postFixup = ''
              wrapProgram $out/bin/workspace-mcp --argv0 workspace-mcp --unset PYTHONPATH
              wrapProgram $out/bin/workspace-cli --argv0 workspace-cli --unset PYTHONPATH
            '';

          });
      workspace-mcp =
        pkgs.runCommand "workspace-mcp-${version}"
          {
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
