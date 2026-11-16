{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      pname = "himalaya-tui";
      version = "root-unstable-2026-11-16";
    in
    {
      packages.himalaya-tui = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "pimalaya";
          repo = "himalaya-tui";
          rev = "fe0fe8ab0c248f2b343754bdb642bfa75b35dedf";
          hash = "sha256-yeSPAtCFwjeNKphS3yWylyRGnHQ6VJPyBFIxAxj9WvE=";
        };

        cargoHash = "sha256-u4UXOjoqeUfQxYs0hKy7n5MbSKXTb7iHlUDbiZYMFXE=";

        passthru.updateScript = packageUpdateScripts.unstable;

        meta = {
          description = "TUI to manage emails";
          homepage = "https://github.com/pimalaya/himalaya-tui";
          license = with lib.licenses; [
            asl20
            mit
          ];
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = pname;
          platforms = lib.platforms.unix;
        };
      };
    };
}
