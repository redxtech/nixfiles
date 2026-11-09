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
      version = "0.45.4";
      src = fetchFromGitHub {
        owner = "trycua";
        repo = "cua";
        tag = "cua-driver-rs-v${version}";
        hash = "sha256-A502cPBCvWm3Txfs6NB8ratr05LblDtTNPR2Cbcp/yo=";
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

        passthru.updateScript = packageUpdateScripts.githubMatchingTag {
          owner = "trycua";
          packageName = pname;
          repo = "cua";
          tagPrefix = "cua-driver-rs-v";
        };

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
