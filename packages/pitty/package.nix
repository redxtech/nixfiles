{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.pitty =
        let
          inherit (pkgs)
            buildNpmPackage
            bun
            fetchFromGitHub
            makeWrapper
            nodejs
            ;

          pname = "pitty";
          version = "0.6.43";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "mistrjirka";
            repo = "PiTTy";
            tag = "v${version}";
            hash = "sha256-ADuyUo0r7jyo6ZdxHIx8XtVBE8O82sXi3PV74KARWd8=";
          };

          npmDepsHash = "sha256-Q8mDdyrjltDwnK9Toslf9kldGBRvVAGMwxpzQnR6lDU=";
          npmDepsFetcherVersion = 2;

          nativeBuildInputs = [ makeWrapper ];

          postPatch = ''
            # Resolve PiTTy's JSX config from its package root while preserving the user's cwd.
            substituteInPlace bin/pitty.mjs \
              --replace-fail \
                'const child = spawn(bun, ["run", `--preload=''${preload}`, entry, ...process.argv.slice(2)], { cwd: process.cwd(), stdio: "inherit", env: childEnv });' \
                'const child = spawn(bun, ["run", `--preload=''${preload}`, entry, "--cwd", process.cwd(), ...process.argv.slice(2)], { cwd: root, stdio: "inherit", env: childEnv });'
          '';

          npmRebuildFlags = [ "--ignore-scripts" ];
          dontNpmBuild = true;

          postInstall = ''
            # OpenTUI deliberately skips its JSX transform for sources below node_modules.
            appRoot="$out/lib/pitty"
            mv "$out/lib/node_modules/pitty-pi-ui" "$appRoot"
            rm -rf "$out/bin" "$out/lib/node_modules"

            bunLink="$appRoot/node_modules/.bin/bun"
            rm -f "$bunLink"
            ln -s ${lib.getExe bun} "$bunLink"

            mkdir -p "$out/bin"
            makeWrapper ${lib.getExe nodejs} "$out/bin/pitty" \
              --add-flags "$appRoot/bin/pitty.mjs" \
              --set PITTY_NO_UPDATE_CHECK 1
            makeWrapper ${lib.getExe nodejs} "$out/bin/pitty-resume" \
              --add-flags "$appRoot/bin/pitty-resume.mjs" \
              --set PITTY_NO_UPDATE_CHECK 1
          '';

          passthru.updateScript = packageUpdateScripts.githubRelease;

          meta = {
            description = "OpenTUI frontend for the Pi coding agent";
            homepage = "https://github.com/mistrjirka/PiTTy";
            changelog = "https://github.com/mistrjirka/PiTTy/releases/tag/v${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "pitty";
            platforms = lib.platforms.unix;
          };
        };
    };
}
