{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      inherit (pkgs)
        buildNpmPackage
        fetchFromGitHub
        fetchurl
        makeWrapper
        nodejs
        stdenvNoCC
        ;

      mkAxiPackage =
        {
          pname,
          version,
          rev,
          hash,
          runtimePackages,
          description,
          updateScript ? null,
        }:
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "thatdudealso";
            repo = pname;
            inherit rev hash;
          };

          nativeBuildInputs = [ makeWrapper ];

          passthru = lib.optionalAttrs (updateScript != null) { inherit updateScript; };

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/lib/${pname}" "$out/bin"
            cp -r bin package.json "$out/lib/${pname}/"
            makeWrapper ${lib.getExe nodejs} "$out/bin/${pname}" \
              --add-flags "$out/lib/${pname}/bin/${pname}.js" \
              --prefix PATH : ${lib.makeBinPath runtimePackages}

            runHook postInstall
          '';

          meta = {
            inherit description;
            homepage = "https://github.com/thatdudealso/${pname}";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = pname;
            platforms = lib.foldl' lib.intersectLists nodejs.meta.platforms (
              map (package: package.meta.platforms) runtimePackages
            );
          };
        };
    in
    {
      packages = {
        docker-axi = mkAxiPackage {
          pname = "docker-axi";
          version = "0-unstable-2026-07-09";
          rev = "dc01c8fad72a15cd9508eb7a5f173998b4fe8330";
          hash = "sha256-1IfyWqZcvXb7f6Ni4sSozB956e/JYp/u1MYCsBu3CF4=";
          runtimePackages = [
            pkgs.docker-client
            pkgs.docker-compose
          ];
          description = "Agent-facing Docker CLI for safe, token-efficient workflows";
          updateScript = packageUpdateScripts.unstable;
        };

        pg-axi = buildNpmPackage {
          pname = "pg-axi";
          version = "0.1.2";

          src = fetchurl {
            url = "https://registry.npmjs.org/pg-axi/-/pg-axi-0.1.2.tgz";
            hash = "sha256-Lok9MlWOHbUrI5lbK9jF1ph2/IpIH4i19hlvGTmTw1k=";
          };

          npmDepsHash = "sha256-e511rYcSxNeFyrOKfuBh4vddCVsh+iUl+YppjJjiBs0=";
          nativeBuildInputs = [ makeWrapper ];
          postPatch = ''
            cp ${./pg-package.json} package.json
            cp ${./pg-package-lock.json} package-lock.json
          '';
          dontNpmBuild = true;
          postFixup = ''
            wrapProgram $out/bin/pg-axi \
              --prefix PATH : ${lib.makeBinPath [ pkgs.postgresql ]}
          '';

          passthru.updateScript = packageUpdateScripts.npm;

          meta = {
            description = "Agent-facing PostgreSQL CLI for safe, token-efficient workflows";
            homepage = "https://github.com/thatdudealso/pg-axi";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.redxtech ];
            mainProgram = "pg-axi";
            platforms = nodejs.meta.platforms;
          };
        };

        kubernetes-axi = mkAxiPackage {
          pname = "kubernetes-axi";
          version = "0-unstable-2026-07-11";
          rev = "c05c686e02cb0074ccf1ba5284d2941c05e9a54e";
          hash = "sha256-SiWOs7pPSckPg7mXmD1Sx5xAdPHuEyYpr99aOsRfN94=";
          runtimePackages = [
            pkgs.kubectl
            pkgs.kubernetes-helm
            pkgs.kustomize
          ];
          description = "Agent-facing Kubernetes CLI for safe, token-efficient workflows";
          updateScript = packageUpdateScripts.unstable;
        };
      };
    };
}
