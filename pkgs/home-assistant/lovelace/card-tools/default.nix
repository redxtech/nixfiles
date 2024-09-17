{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "lovelace-card-tools";
  version = "11";

  src = fetchFromGitHub {
    owner = "thomasloven";
    repo = pname;
    rev = version;
    hash = "sha256-QpRSD3aFT12/nGykMnRZt9aLCU1fJ3r+8WPE4681LbA=";
  };

  npmDepsHash = "sha256-hTk8d5sSUlaOWfJ/zh1dXj5gu4dlnMh/AgsVVQge2tE=";

  NODE_OPTIONS = "--openssl-legacy-provider";

  installPhase = ''
    mkdir $out
    cp -r card-tools.js $out
  '';

  passthru.entrypoint = "card-tools.js";

  meta = with lib; {
    changelog =
      "https://github.com/thomasloven/lovelace-card-tools/releases/tag/${version}";
    description = "A collection of tools for other lovelace plugins to use";
    homepage = "https://github.com/thomasloven/lovelace-card-tools";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
  };
}
