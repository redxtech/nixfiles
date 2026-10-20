{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-lovelace-grid-remote-card = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "grid-remote-card";
        version = "1.8.0";

        src = pkgs.fetchFromGitHub {
          owner = "thecodingdad";
          repo = "grid-remote-card";
          tag = "v${version}";
          hash = "sha256-nFWAxtHi1XjoTyfCZipkI4qj2ayjFznoyUVzoTJbT6c=";
        };

        dontBuild = true;

        installPhase = ''
          runHook preInstall

          install -Dm444 dist/grid-remote-card.js $out/grid-remote-card.js
          install -Dm444 LICENSE $out/share/doc/${pname}/LICENSE

          runHook postInstall
        '';

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          changelog = "https://github.com/thecodingdad/grid-remote-card/releases/tag/v${version}";
          description = "Customizable TV and media remote control card for Home Assistant";
          homepage = "https://github.com/thecodingdad/grid-remote-card";
          maintainers = [ lib.maintainers.redxtech ];
          license = lib.licenses.mit;
          platforms = lib.platforms.all;
        };
      };
    };
}
