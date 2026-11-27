{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      pname = "ramwho";
      version = "0.1.0";
    in
    {
      packages.ramwho = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "giladashubham";
          repo = pname;
          tag = "v${version}";
          hash = "sha256-Bw/HtmJZ9UeOso1TVEdxTXEqws1hrTnouyRd6flrY9g=";
        };

        cargoHash = "sha256-w93oT63A7EhUI/nCEsYI1Z+fI7EJN9xkYp3GfGCU7Qk=";

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          description = "Terminal process monitor that groups memory usage by application";
          homepage = "https://github.com/giladashubham/ramwho";
          changelog = "https://github.com/giladashubham/ramwho/releases/tag/v${version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = pname;
          platforms = lib.platforms.linux;
        };
      };
    };
}
