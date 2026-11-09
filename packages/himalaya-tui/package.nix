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
      version = "root-unstable-2026-11-08";
    in
    {
      packages.himalaya-tui = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "pimalaya";
          repo = "himalaya-tui";
          rev = "4c2af0f0caea64beda66ebd230387da1434ff9d7";
          hash = "sha256-J6qCJkCBA+sjYSpPytusgugWhgBGr0CVLS124GHb7Do=";
        };

        cargoHash = "sha256-lCnFdvWBbPdq08AvhD30+/9cfGwtRzOwrW5DhLGuA+g=";

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
