{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      version = "1.202610.9";
      piVersion = "1.4.0";
      updateScript = packageUpdateScripts.nodeScript {
        packageName = "pi-web";
        script = ./update.mjs;
        args = [ "packages/pi-web" ];
        nodejs = pkgs.nodejs_24;
        runtimeInputs = [
          pkgs.nix
          pkgs.prefetch-npm-deps
        ];
      };
    in
    {
      packages.pi-web = pkgs.buildNpmPackage {
        pname = "pi-web";
        inherit version;
        nodejs = pkgs.nodejs_24;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@jmfederico/pi-web/-/pi-web-${version}.tgz";
          hash = "sha256-g85tS2LS80C/K6qhL+zxr760eHqC4UA80BWYCXEZ2hg=";
        };

        npmDepsHash = "sha256-Ggd8TRYRnaoIFylCJLH6w+FhtH8V6UIqOysUmxkYSdA=";
        npmDepsFetcherVersion = 2;
        postPatch = ''
          # match the CLI's SDK without pulling a newer pi peer dependency
          ${lib.getExe pkgs.jq} 'del(.scripts, .devDependencies, .peerDependenciesMeta) | .peerDependencies |= with_entries(.value = "${piVersion}")' \
            package.json > package.json.tmp
          mv package.json.tmp package.json
          cp ${./package-lock.json} package-lock.json
        '';

        npmRebuildFlags = [ "--ignore-scripts" ];
        dontNpmBuild = true;
        # the lock contains only runtime dependencies, so pruning is unnecessary
        dontNpmPrune = true;
        postBuild = ''
          # terminals need node-pty's native binding, not dependency install scripts
          npm pkg set 'allowScripts.node-pty=true' --json
          npm rebuild node-pty
        '';

        passthru = {
          inherit piVersion;
          updateScript = lib.getExe updateScript;
        };

        meta = {
          description = "Web UI for persistent Pi Coding Agent sessions";
          homepage = "https://pi-web.dev/";
          license = lib.licenses.mit;
          mainProgram = "pi-web";
          platforms = lib.platforms.linux;
        };
      };
    };
}
