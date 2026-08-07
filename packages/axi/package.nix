{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        fetchFromGitHub
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
        }:
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "thatdudealso";
            repo = pname;
            inherit rev hash;
          };

          nativeBuildInputs = [ makeWrapper ];

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
          version = "0.1.0";
          rev = "dc01c8fad72a15cd9508eb7a5f173998b4fe8330";
          hash = "sha256-1IfyWqZcvXb7f6Ni4sSozB956e/JYp/u1MYCsBu3CF4=";
          runtimePackages = [
            pkgs.docker-client
            pkgs.docker-compose
          ];
          description = "Agent-facing Docker CLI for safe, token-efficient workflows";
        };

        pg-axi = mkAxiPackage {
          pname = "pg-axi";
          version = "0.1.0";
          rev = "48701411a50d45458f5fffb627f93eef0d57a0b3";
          hash = "sha256-i5RDPRVpB0YBtDdvUH2lsDYXaaJ3XR6Cgh61DEfRMcw=";
          runtimePackages = [ pkgs.postgresql ];
          description = "Agent-facing PostgreSQL CLI for safe, token-efficient workflows";
        };

        kubernetes-axi = mkAxiPackage {
          pname = "kubernetes-axi";
          version = "0.1.0";
          rev = "c05c686e02cb0074ccf1ba5284d2941c05e9a54e";
          hash = "sha256-SiWOs7pPSckPg7mXmD1Sx5xAdPHuEyYpr99aOsRfN94=";
          runtimePackages = [
            pkgs.kubectl
            pkgs.kubernetes-helm
            pkgs.kustomize
          ];
          description = "Agent-facing Kubernetes CLI for safe, token-efficient workflows";
        };
      };
    };
}
