{
  perSystem =
    { pkgs, lib, ... }:
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
          version = "0.4.0";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchurl {
            url = "https://registry.npmjs.org/cyber-mux/-/cyber-mux-${version}.tgz";
            hash = "sha256-gi+mTRvZ2jU6lW+BGJUFN4leMcP/Xop2XKlZAvF10zM=";
          };

          npmDepsHash = "sha256-rLMr7NK4gKkCjfJvC6rwUpnXVtzflQ7zyahwc908ByM=";

          nativeBuildInputs = [ makeWrapper ];

          postPatch = ''
            substituteInPlace dist/cli.mjs src/cli.ts \
              --replace-fail '0.0.0' '${version}'
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
          '';

          dontNpmBuild = true;

          postFixup = ''
            wrapProgram $out/bin/cyber-mux \
              --prefix PATH : ${
                lib.makeBinPath [
                  git
                  procps
                ]
              }
          '';

          passthru.updateScript = pkgs.nix-update-script { };

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
