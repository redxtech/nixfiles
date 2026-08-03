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

      version = "0.37.0";
      src = fetchFromGitHub {
        owner = "repowise-dev";
        repo = "repowise";
        tag = "v${version}";
        hash = "sha256-S9wtzrhxADG96hMd7V3Mr2k8M5jCtT3x6wxv0Egf/mg=";
      };

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      buildOverlay = final: prev: {
        numpy = prev.numpy.overrideAttrs (oldAttrs: {
          nativeBuildInputs =
            oldAttrs.nativeBuildInputs
            ++ [ pkgs.ninja ]
            ++ final.resolveBuildSystem {
              cython = [ ];
              meson-python = [ ];
            };
        });
      };
      pythonSet = (pkgs.callPackage pyproject-nix.build.packages { python = python313; }).overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          overlay
          buildOverlay
        ]
      );
      repowiseEnv =
        (pythonSet.mkVirtualEnv "repowise-${version}" workspace.deps.default).overrideAttrs
          (oldAttrs: {
            nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ makeWrapper ];
            postFixup = ''
              wrapProgram $out/bin/repowise --unset PYTHONPATH
              wrapProgram $out/bin/repowise-augment --unset PYTHONPATH
              wrapProgram $out/bin/repowise-rewrite --unset PYTHONPATH
            '';
          });
      repowise =
        pkgs.runCommand "repowise-${version}"
          {
            meta = {
              description = "Codebase intelligence layer for AI coding agents";
              homepage = "https://github.com/repowise-dev/repowise";
              changelog = "https://github.com/repowise-dev/repowise/releases/tag/v${version}";
              license = lib.licenses.agpl3Plus;
              maintainers = [ lib.maintainers.redxtech ];
              mainProgram = "repowise";
            };
          }
          ''
            mkdir -p $out/bin
            ln -s ${repowiseEnv}/bin/repowise $out/bin/repowise
            ln -s ${repowiseEnv}/bin/repowise-augment $out/bin/repowise-augment
            ln -s ${repowiseEnv}/bin/repowise-rewrite $out/bin/repowise-rewrite
          '';
    in
    {
      packages = { inherit repowise; };
    };
}
