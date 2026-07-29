{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs) stdenv fetchurl;

      version = "2.1.0";
      sources = {
        x86_64-linux = {
          arch = "x64";
          hash = "sha256-UW6faT7KTJjTInuSnmWblNYXDTmBS+5cFr0GlxMWvzU=";
        };
        aarch64-linux = {
          arch = "arm64";
          hash = "sha256-NktilO3P34knaN8I8V+mFusOoJxVjtZD30Dj657N5Lg=";
        };
      };
      source = sources.${stdenv.hostPlatform.system};
      vaulted-unwrapped = stdenv.mkDerivation {
        pname = "vaulted-unwrapped";
        inherit version;

        src = fetchurl {
          url = "https://github.com/woosal1337/vaulted/releases/download/v${version}/vaulted-v${version}-linux-${source.arch}.tar.gz";
          inherit (source) hash;
        };

        sourceRoot = ".";
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp vaulted $out/bin/
          cp -r prebuilds $out/bin/

          runHook postInstall
        '';
      };
    in
    {
      packages.vaulted = pkgs.buildFHSEnv {
        name = "vaulted";
        runScript = lib.getExe' vaulted-unwrapped "vaulted";
        meta = {
          description = "Local-first secrets manager for AI coding agents";
          homepage = "https://vaulted.chele.bi";
          changelog = "https://github.com/woosal1337/vaulted/releases/tag/v${version}";
          license = lib.licenses.mit;
          mainProgram = "vaulted";
          platforms = builtins.attrNames sources;
        };
      };
    };
}
