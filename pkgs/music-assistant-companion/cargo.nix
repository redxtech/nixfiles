{ lib, rustPlatform, fetchFromGitHub, mkYarnPackage, cargo-tauri, pkg-config
, nodePackages, libayatana-appindicator, gtk3, webkitgtk, libsoup, openssl }:

let
  pname = "music-assistant-desktop";
  version = "0.0.72";

  src = fetchFromGitHub {
    owner = "music-assistant";
    repo = "companion";
    rev = "v${version}";
    hash = "sha256-YcLR9XIU4OUOKrONQSB5qhdhlz5I/neFRO6yORuAe8I=";
  };

  frontend = mkYarnPackage rec {
    pname = "music-assistant-frontend";
    version = "2.8.13";

    src = fetchFromGitHub {
      owner = "music-assistant";
      repo = "frontend";
      rev = version;
      hash = "sha256-goYg1fToeByANX2BlD/idX4HiyBZuUBAnpkg0SxnC1E=";
    };

    buildPhase = ''
      export HOME=$(mktemp -d)
      yarn --offline build
      cp -r deps/frontend $out/
    '';

    distPhase = "true";
  };
in rustPlatform.buildRustPackage rec {
  inherit pname version src;

  sourceRoot = "${src.name}/src-tauri";
  cargoLock.lockFile = src + "src-tauri/Cargo.lock";

  postPatch = ''
    cp ${src}/src-tauri/Cargo.lock Cargo.lock

    mkdir -p frontend
    ln -s ${frontend}/music_assistant_frontend frontend/dist

    substituteInPlace tauri.conf.json --replace '"distDir": "../out/src",' '"distDir": "frontend-build/src",'
    # substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
    #   --replace-warn "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';

  nativeBuildInputs =
    [ rustPlatform.cargoSetupHook cargo-tauri nodePackages.yarn pkg-config ];

  buildInputs = [ libayatana-appindicator openssl libsoup gtk3 webkitgtk ];

  preBuild = ''
    yarn install --offline --frozen-lockfile --no-optional --ignore-script
    # Use cargo-tauri from nixpkgs instead of pnpm tauri from npm
    cargo tauri build -b deb
  '';

  preInstall = ''
    mv target/release/bundle/deb/*/data/usr/ $out
  '';

  postInstall = ''
    mv $out/bin/app $out/bin/music-assistant-desktop
  '';

  meta = with lib; {
    description = "";
    mainProgram = "";
    homepage = "";
    platforms = platforms.linux;
    license = licenses.asl20;
    maintainers = with maintainers; [ redxtech ];
  };
}

