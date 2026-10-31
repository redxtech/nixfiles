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
      version = "root-unstable-2026-10-27";
    in
    {
      packages.himalaya-tui = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "pimalaya";
          repo = "himalaya-tui";
          rev = "d578c08ac355f423f775ba189d5c868fb9647095";
          hash = "sha256-IkwfeDdHmnUximKlnIzLHo5qmF+lCuF93ABYkXDv4NU=";
        };

        cargoHash = "sha256-QJ+SfK5kC16YeuWa9yW5HiqQZl/Te/ecP0aXRSgBp40=";

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
