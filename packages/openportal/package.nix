{
  perSystem =
    {
      pkgs,
      packageUpdateScripts,
      ...
    }:
    let
      inherit (pkgs)
        bun
        fetchurl
        lib
        makeWrapper
        stdenvNoCC
        ;

      version = "0.1.32";

      src = fetchurl {
        url = "https://registry.npmjs.org/openportal/-/openportal-${version}.tgz";
        hash = "sha256-T/or2oyGwvKLaGSnY+gNVUY4oxcAsnd7Lm1qJ4ZgJCs=";
      };
    in
    {
      packages.openportal = stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "openportal";
        inherit version src;

        nativeBuildInputs = [ makeWrapper ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/openportal $out/bin
          cp -r dist web $out/lib/openportal/
          makeWrapper ${lib.getExe bun} $out/bin/openportal \
            --add-flags $out/lib/openportal/dist/index.js \
            --prefix PATH : ${lib.makeBinPath [ bun ]}

          runHook postInstall
        '';

        passthru.updateScript = packageUpdateScripts.npm;

        meta = {
          description = "Mobile-first web interface for coding agents";
          homepage = "https://github.com/hosenur/portal";
          changelog = "https://github.com/hosenur/portal/releases/tag/cli-v${finalAttrs.version}";
          license = lib.licenses.mit;
          mainProgram = "openportal";
          platforms = lib.platforms.linux;
        };
      });
    };
}
