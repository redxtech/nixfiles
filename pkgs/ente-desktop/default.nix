{ lib, fetchurl, appimageTools, imagemagick, ... }:

let
  pname = "ente-desktop";
  version = "1.7.0";
  name = "${pname}-${version}";

  src = fetchurl {
    url =
      "https://github.com/ente-io/photos-desktop/releases/download/v${version}/ente-${version}-x86_64.AppImage";
    name = "${name}.AppImage";
    hash = "sha256-utmUKTF+0+z3He/uKCiWG4BdZZxQDssgNvXGhyR/AMQ=";
  };

  appimageContents = appimageTools.extractType2 { inherit name src; };
in appimageTools.wrapType2 {
  inherit name src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash ];

  extraInstallCommands = ''
    ln -s $out/bin/${name} $out/bin/${pname}

    install -m 444 -D ${appimageContents}/ente.desktop $out/share/applications/ente.desktop

    mkdir -p $out/share/icons/hicolor/512x512/apps
    ${imagemagick}/bin/convert ${appimageContents}/usr/share/icons/hicolor/0x0/apps/ente.png -resize 512x512 $out/share/icons/hicolor/512x512/apps/ente.png

    substituteInPlace $out/share/applications/ente.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=ente-desktop'
  '';

  meta = with lib; {
    description = "";
    homepage = "";
    changelog = "";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
