{
  perSystem =
    { pkgs, lib, ... }:
    let
      version = "1.202610.1";
      piVersion = "1.0.0";
      updateScript = pkgs.writeShellApplication {
        name = "update-pi-web";
        runtimeInputs = [
          pkgs.nodejs_24
          pkgs.nix
          pkgs.prefetch-npm-deps
        ];
        text = ''
          node ${./update.mjs}
        '';
      };
    in
    {
      packages.pi-web = pkgs.buildNpmPackage {
        pname = "pi-web";
        inherit version;
        nodejs = pkgs.nodejs_24;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@jmfederico/pi-web/-/pi-web-${version}.tgz";
          hash = "sha256-NGJLlXnwlcdBt+HtFNsWeN7GmHTmRlyNi+RQerF2hcI=";
        };

        npmDepsHash = "sha256-xlNYO6gVwSvgENJ0zepXj663d/htJZ8107SphPvSJuE=";
        npmDepsFetcherVersion = 2;
        postPatch = ''
          # match the CLI's SDK without pulling a newer pi peer dependency
          ${lib.getExe pkgs.jq} 'del(.scripts, .devDependencies) | .peerDependencies |= with_entries(.value = "${piVersion}")' \
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
