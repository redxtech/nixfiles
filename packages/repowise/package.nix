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

      version = "0.47.0";
      src = fetchFromGitHub {
        owner = "repowise-dev";
        repo = "repowise";
        tag = "v${version}";
        hash = "sha256-6FfEBOwJERFyA8ddnh4YAQ4ZGzKLkse9Sg+6zKy7d1Y=";
      };
      updateScript = pkgs.writeShellApplication {
        name = "update-repowise";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          python3
        ];
        text = ''
          packageFile=packages/repowise/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/repowise-dev/repowise/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"
          sourceHash="$(
            nix store prefetch-file --unpack --json \
              "https://github.com/repowise-dev/repowise/archive/refs/tags/$tag.tar.gz" \
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
            passthru.updateScript = lib.getExe updateScript;
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
