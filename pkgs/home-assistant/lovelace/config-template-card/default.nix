{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "config-template-card";
  version = "1.3.6";

  src = fetchurl {
    url =
      "https://github.com/iantrich/config-template-card/releases/download/${version}/config-template-card.js";
    hash = "sha256-7O48fgoQkg6aQy3i5/H5UGrnQkJelXQdGDW71N6lbC4=";
  };

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
    changelog =
      "https://github.com/iantrich/config-template-card/releases/tag/${version}";
    description = "Templatable Lovelace Configurations";
    homepage = "https://github.com/iantrich/config-template-card";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
