{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-lovelace-layout-card =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchFromGitHub
            ;
        in
        buildNpmPackage rec {
          pname = "lovelace-layout-card";
          version = "2.4.7";

          src = fetchFromGitHub {
            owner = "thomasloven";
            repo = pname;
            rev = "v${version}";
            hash = "sha256-xni9cTgv5rdpr+Oo4Zh/d/2ERMiqDiTFGAiXEnigqjc=";
          };

          npmDepsHash = "sha256-Nmi51kCj/e9A0PmO/DIvOplgBnQzIEmCbuM5HjmdKGw=";

          installPhase = ''
            mkdir $out
            cp -r layout-card.js $out
          '';

          passthru = {
            entrypoint = "layout-card.js";
            updateScript = packageUpdateScripts.githubReleaseWithRegex "v?([0-9]+\\.[0-9]+\\.[0-9]+)";
          };

          meta = with lib; {
            changelog = "https://github.com/thomasloven/lovelace-layout-card/releases/tag/v${version}";
            description = "Get more control over the placement of lovelace cards.";
            homepage = "https://github.com/thomasloven/lovelace-layout-card";
            license = licenses.mit;
            maintainers = with maintainers; [ redxtech ];
          };
        };
    };
}
