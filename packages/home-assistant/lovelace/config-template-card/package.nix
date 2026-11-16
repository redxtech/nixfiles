{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-lovelace-config-template-card =
        let
          inherit (pkgs)
            stdenvNoCC
            fetchurl
            ;
        in
        stdenvNoCC.mkDerivation rec {
          pname = "config-template-card";
          version = "2.1.0";

          src = fetchurl {
            url = "https://github.com/iantrich/config-template-card/releases/download/${version}/config-template-card.js";
            hash = "sha256-RbLcNHgDkkIIE70p2KlNoP8m7jdGJo2eChhbSXqfe5c=";
          };

          passthru.updateScript = packageUpdateScripts.githubRelease;

          unpackPhase = ":";

          buildPhase = ''
            cp $src config-template-card.js

            sed -i -E 's/\*\/console.warn\("The main .lit-element..*"\)\;/*\//g' config-template-card.js
          '';

          installPhase = ''
            mkdir $out
            cp config-template-card.js $out
          '';

          distPhase = "true";

          meta = with lib; {
            changelog = "https://github.com/iantrich/config-template-card/releases/tag/${version}";
            description = "Templatable Lovelace Configurations";
            homepage = "https://github.com/iantrich/config-template-card";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.mit;
          };
        };
    };
}
