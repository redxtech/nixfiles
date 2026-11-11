{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.codebase-memory-mcp = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "codebase-memory-mcp";
        version = "0.12.1";

        src = pkgs.fetchFromGitHub {
          owner = "DeusData";
          repo = "codebase-memory-mcp";
          tag = "v${finalAttrs.version}";
          hash = "sha256-qmLm6jALuPUh6+gSEmWzECWL7AC8HOHAbUHDpYOJlbs=";
        };

        nativeBuildInputs = [ pkgs.gnumake ];
        buildInputs = [ pkgs.zlib ];

        # keep mimalloc's direct API without the libc interposition that crashes at startup
        postPatch = lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          substituteInPlace Makefile.cbm \
            --replace-fail 'ifneq ($(filter yes,$(IS_MINGW) $(IS_LINUX)),)' 'ifneq ($(filter yes,$(IS_MINGW)),)'
        '';

        # upstream's build script rejects the nix compiler wrapper, so invoke make directly
        buildPhase = ''
          runHook preBuild
          make -j$NIX_BUILD_CORES -f Makefile.cbm cbm
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 build/c/codebase-memory-mcp $out/bin/codebase-memory-mcp
          runHook postInstall
        '';

        doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
        installCheckPhase = ''
          runHook preInstallCheck
          $out/bin/codebase-memory-mcp --version
          runHook postInstallCheck
        '';

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          description = "MCP server that builds and queries a semantic graph of your codebase";
          homepage = "https://github.com/DeusData/codebase-memory-mcp";
          license = lib.licenses.mit;
          mainProgram = "codebase-memory-mcp";
          platforms = [
            "aarch64-darwin"
            "x86_64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ];
        };
      });
    };
}
