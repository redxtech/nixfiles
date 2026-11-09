{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cyber-mux =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchurl
            git
            makeWrapper
            procps
            ;

          pname = "cyber-mux";
          version = "0.12.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/cyber-mux/-/cyber-mux-${version}.tgz";
            hash = "sha256-xdgNfwolCVBskp4+p0M36SQc1L0Op7TSxKlAvZIF7vQ=";
          };

          npmDepsHash = "sha256-vBjVSoLyLTmVGz9U3VRXCWOYdpDoldupRCNvZiTQ8To=";
          npmDepsFetcherVersion = 2;

          nativeBuildInputs = [ makeWrapper ];

          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
          '';

          npmRebuildFlags = [ "--ignore-scripts" ];
          dontNpmBuild = true;
          doInstallCheck = true;
          installCheckPhase = ''
            runHook preInstallCheck
            $out/bin/cyber-mux --version | grep -Fx "${version}"
            $out/bin/cyber-mux --help > /dev/null
            runHook postInstallCheck
          '';

          postFixup = ''
            wrapProgram $out/bin/cyber-mux \
              --prefix PATH : ${
                lib.makeBinPath [
                  git
                  procps
                ]
              }
          '';

          passthru.updateScript = packageUpdateScripts.npmWithLockfile pname;

          meta = {
            description = "Cross-multiplexer pane control for AI-agent tooling";
            homepage = "https://github.com/cyberuni/cyber-mux";
            changelog = "https://github.com/cyberuni/cyber-mux/releases/tag/cyber-mux%40${version}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "cyber-mux";
            platforms = lib.platforms.linux;
          };
        };
    };
}
