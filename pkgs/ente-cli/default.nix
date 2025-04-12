{
  lib,
  stdenv,
  fetchzip,
  nix-update-script,
}:

stdenv.mkDerivation rec {
  pname = "ente-cli";
  version = "0.2.3";

  src = fetchzip {
    url = "https://github.com/ente-io/ente/releases/download/cli-v${version}/ente-cli-v${version}-linux-arm64.tar.gz";
    hash = "sha256-ATbBZiDMlCeZvc+Df42yu1p4kvgpeB6PzyeabzBC770=";
  };

  installPhase = ''
    mkdir -p $out/bin
    ln -s $src/ente $out/bin/ente
  '';

  passthru.updateScript = nix-update-script {
		# TODO: test when fixed. currently can't see a 'clu-v*' release since it's not in the last 10 releases
		extraArgs = [ "--version-regex" "cli-v(.*)" ];
	};

  meta = with lib; {
    description = "The Ente CLI is a Command Line Utility for exporting data from Ente.";
    homepage = "https://github.com/ente-io/ente/tree/main/cli";
    changelog = "https://github.com/ente-io/ente/releases/tag/cli-v${version}";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
