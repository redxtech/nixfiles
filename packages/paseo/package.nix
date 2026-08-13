{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs)
        autoPatchelfHook
        buildNpmPackage
        fetchFromGitHub
        libuv
        makeWrapper
        python3
        stdenv
        ;

      nodejs = pkgs.nodejs_22;
      pname = "paseo";
      version = "0.3.1";

      source = fetchFromGitHub {
        owner = "getpaseo";
        repo = "paseo";
        tag = "v${version}";
        hash = "sha256-m97Pf857LNv871b95cJ2y34OFxoES8JsWsp0wD3Em4I=";
      };
      updateScript = pkgs.writeShellApplication {
        name = "update-paseo";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          nix-update
          python3
        ];
        text = ''
          packageFile=packages/paseo/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/getpaseo/paseo/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"
          sourceHash="$(
            nix store prefetch-file --unpack --json \
              "https://github.com/getpaseo/paseo/archive/refs/tags/$tag.tar.gz" \
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

          nix-update --flake --no-src --version="$version" "''${UPDATE_NIX_ATTR_PATH:-paseo}"
        '';
      };
    in
    {
      packages.paseo = buildNpmPackage {
        inherit pname version;

        # The monorepo contains native and desktop sources that the CLI and daemon builds do not use.
        src = lib.cleanSourceWith {
          src = source;
          filter =
            path: _:
            let
              baseName = builtins.baseNameOf path;
              relativePath = lib.removePrefix (toString source) path;
              excludedPrefixes = [
                "/packages/app/android"
                "/packages/app/ios"
                "/packages/website/src"
                "/packages/website/public"
                "/packages/desktop/src"
              ];
            in
            !(lib.any (prefix: lib.hasPrefix prefix relativePath) excludedPrefixes)
            && !(lib.hasSuffix ".test.ts" baseName)
            && baseName != "node_modules"
            && baseName != ".git"
            && baseName != ".paseo"
            && baseName != ".DS_Store";
        };

        inherit nodejs;
        npmDepsHash = "sha256-oXz8hMk+5DlTYK8OndUAjB+RJMDbPqobVGXLFeoH++o=";

        # onnxruntime-node downloads from NuGet in its install script; node-pty is rebuilt explicitly below.
        npmRebuildFlags = [ "--ignore-scripts" ];

        nativeBuildInputs = [
          python3
          makeWrapper
        ]
        ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

        buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
          libuv
          stdenv.cc.cc.lib
        ];

        dontNpmBuild = true;

        buildPhase = ''
          runHook preBuild

          npm rebuild node-pty
          npm run build:server
          npm run build:daemon-web-ui

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          installRoot="$out/lib/paseo"
          mkdir -p "$installRoot"

          # Upstream's static trace is the source of truth for the minimal daemon runtime closure.
          node scripts/trace-daemon.mjs > daemon-files.txt

          while IFS= read -r path; do
            [ -z "$path" ] && continue
            mkdir -p "$installRoot/$(dirname "$path")"
            cp -a "$path" "$installRoot/$path"
          done < daemon-files.txt

          cp package.json "$installRoot/"
          cp -r packages/server/dist/server/web-ui "$installRoot/packages/server/dist/server/"

          mkdir -p "$out/bin"
          makeWrapper ${nodejs}/bin/node "$out/bin/paseo-server" \
            --add-flags "$installRoot/packages/server/dist/scripts/supervisor-entrypoint.js" \
            --set NODE_ENV production

          makeWrapper ${nodejs}/bin/node "$out/bin/paseo" \
            --add-flags "$installRoot/packages/cli/dist/index.js" \
            --set NODE_PATH "$installRoot/node_modules"

          runHook postInstall
        '';

        passthru.updateScript = lib.getExe updateScript;

        meta = {
          description = "Control AI coding agents from the command line";
          homepage = "https://github.com/getpaseo/paseo";
          changelog = "https://github.com/getpaseo/paseo/releases/tag/v${version}";
          license = lib.licenses.agpl3Plus;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "paseo";
          platforms = lib.platforms.linux ++ lib.platforms.darwin;
        };
      };
    };
}
