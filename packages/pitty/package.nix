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
          version = "0.5.18";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "mistrjirka";
            repo = "PiTTy";
            tag = "v${version}";
            hash = "sha256-wZJYRfonK3uE8QJ2p8Urd4kYHF14UY9dRRFGFQH2DQY=";
          };

          npmDepsHash = "sha256-TvA5Bp6r+O4h2rTQjMjqaeYzwAkfRw2auj/b6TpxjPQ=";
          npmDepsFetcherVersion = 2;

          nativeBuildInputs = [ makeWrapper ];

          postPatch = ''
            # The upstream lockfile omits integrity hashes for three nested Pi packages.
            substituteInPlace package-lock.json \
              --replace-fail \
                '"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.6.tgz",' \
                $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.6.tgz",\n      "integrity": "sha512-Lvn89ko42h5ETUb6Z0Ku6ldskEqXaTdQBYvSa0+7bdG9V6rUEpXptv5e0OVZ1HDcvi8s6/2lGCQWsxKX+DFHNw==",' \
              --replace-fail \
                '"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.6.tgz",' \
                $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.6.tgz",\n      "integrity": "sha512-7xfLk8sANBp+bpPEbjoOZTbPxsa+++b1JXAoSJsNa3vbs9AHHEclmvg54XLQcxH+fuwaeti/g2jeIfJ+mVYLpA==",' \
              --replace-fail \
                '"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.6.tgz",' \
                $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.6.tgz",\n      "integrity": "sha512-bSuzS4EVSqEPj/Qr/p9eqCESfKsGuDNbl77EGci8Iaqqt/C/XCBZL1MjXaxSWW1NsT5afjp/Cb0NTPzOLv/aPA==",'

            # Resolve PiTTy's JSX config from its package root while preserving the user's cwd.
            substituteInPlace bin/pitty.mjs \
              --replace-fail \
                'const child = spawn(bun, ["run", `--preload=''${preload}`, path.join(root, "src", "index.tsx"), ...process.argv.slice(2)], { cwd: process.cwd(), stdio: "inherit", env: childEnv });' \
                'const child = spawn(bun, ["run", `--preload=''${preload}`, path.join(root, "src", "index.tsx"), "--cwd", process.cwd(), ...process.argv.slice(2)], { cwd: root, stdio: "inherit", env: childEnv });'
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
