{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "lovelace-layout-card";
  version = "2.4.5";

  src = fetchFromGitHub {
    owner = "thomasloven";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-JqHpd3u3HT9JuAfCQW0Bg/UIQ/pzurQBp9/PFa+0/u0=";
  };

  npmDepsHash = "sha256-1Crvtux1IbdtZ5dMxhYcrCw/6IxLpNwNwUMEJpWm4HM=";

  installPhase = ''
    mkdir $out
    cp -r layout-card.js $out
  '';

  passthru.entrypoint = "layout-card.js";

  meta = with lib; {
    changelog =
      "https://github.com/thomasloven/lovelace-layout-card/releases/tag/v${version}";
    description = "Get more control over the placement of lovelace cards.";
    homepage = "https://github.com/thomasloven/lovelace-layout-card";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
  };
}
