{
  perSystem =
    { pkgs, lib, ... }:
    let
      pname = "himalaya-tui";
      version = "0.1.0-unstable-2026-08-16";
    in
    {
      packages.himalaya-tui = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "pimalaya";
          repo = "himalaya-tui";
          rev = "beed4ed3c801f49a8754f105155b2eef7a200d90";
          hash = "sha256-8tL6rj93FyEgnedgRPX8EJirj8xPzn7M7osDfP3f5sg=";
        };

        cargoHash = "sha256-SCeORnZilEHWOWAuC6iOpxcLZa8iQRcuN4Y+vpskJK0=";

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
