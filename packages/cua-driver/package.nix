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
        fetchFromGitHub
        libei
        libx11
        libxext
        libxi
        libxkbcommon
        libxtst
        pipewire
        pkg-config
        ;

      pname = "cua-driver";
      version = "0.19.3";
      src = fetchFromGitHub {
        owner = "trycua";
        repo = "cua";
        tag = "cua-driver-rs-v${version}";
        hash = "sha256-oAwjzNspkCsM+2PgNhoyUi7xZwY430kNAesSU84xM1k=";
        postFetch = ''
          find "$out" -mindepth 1 -maxdepth 1 ! -name libs -exec rm -rf {} +
          find "$out/libs" -mindepth 1 -maxdepth 1 ! -name cua-driver -exec rm -rf {} +
          find "$out/libs/cua-driver" -mindepth 1 -maxdepth 1 ! -name rust ! -name wayland-helper -exec rm -rf {} +
        '';
      };
    in
    {
      packages.cua-driver = pkgs.rustPlatform.buildRustPackage {
        inherit pname version src;

        sourceRoot = "${src.name}/libs/cua-driver/rust";
        cargoLock.lockFile = "${src}/libs/cua-driver/rust/Cargo.lock";

        cargoBuildFlags = [
          "--package"
          pname
          "--features"
          "portal-input,portal-capture"
        ];

        nativeBuildInputs = [
          pkg-config
          pkgs.rustPlatform.bindgenHook
        ];

        buildInputs = [
          libei
          libx11
          libxext
          libxi
          libxkbcommon
          libxtst
          pipewire
        ];

        doCheck = false;

        passthru.updateScript = packageUpdateScripts.githubTagWithRegex "cua-driver-rs-v([0-9]+\\.[0-9]+\\.[0-9]+)";

        meta = {
          description = "Cross-platform MCP server for computer-use automation";
          homepage = "https://github.com/trycua/cua";
          changelog = "https://github.com/trycua/cua/releases/tag/cua-driver-rs-v${version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = pname;
          platforms = lib.platforms.linux;
        };
      };
    };
}
