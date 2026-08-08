{
  perSystem =
    { pkgs, lib, ... }:
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
      version = "0.2.5";

      source = fetchFromGitHub {
        owner = "getpaseo";
        repo = "paseo";
        tag = "v${version}";
        hash = "sha256-3IMEyJS0z83peC1Vzvtj2m+7hm3Uss1qOoE5sMGFITM=";
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
        npmDepsHash = "sha256-FbAuGkXHC6uCLED4X6vOW/T5eUrdxAxNZME6gWsc0w0=";

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

        passthru.updateScript = pkgs.nix-update-script { };

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
