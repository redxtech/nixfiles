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
      version = "root-unstable-2026-11-02";
    in
    {
      packages.himalaya-tui = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "pimalaya";
          repo = "himalaya-tui";
          rev = "467b476f6a8f84bd6f504b418a0eaeff7d23259e";
          hash = "sha256-zr9eQVyM2d5s2Z1oSBWBXPfynhCFo5nULey7ZxaUgK0=";
        };

        cargoHash = "sha256-o/SmlcmRk3adhu/j0gL5hsnH31vDB1Jc9hqftDlnYik=";

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
