{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "lovelace-grocy-chores-card";
  version = "3.8.2";

  src = fetchFromGitHub {
    owner = "isabellaalstrom";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-R6vMWNKjPl45fR2NRWu4AQ5uXdlAWmQ5juL+6/6vMp0=";
  };

  npmDepsHash = "sha256-7qMpjiCMHqSqgnCV28xh6WGS0lbck7vH2DQqGQOUoXA=";

  installPhase = ''
    mkdir $out
    cp -r output/grocy-chores-card.js $out
  '';

  passthru.entrypoint = "grocy-chores-card.js";

  meta = with lib; {
    changelog =
      "https://github.com/isabellaalstrom/lovelace-grocy-chores-card/releases/tag/v${version}";
    description = "A card to track chores and tasks in Grocy.";
    homepage = "https://github.com/isabellaalstrom/lovelace-grocy-chores-card";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
  };
}
