{ lib, fetchurl, appimageTools, ... }:

let
  pname = "ente-desktop";
  version = "1.7.11";
  name = "${pname}-${version}";

  src = fetchurl {
    url =
      "https://github.com/ente-io/photos-desktop/releases/download/v${version}/ente-${version}-x86_64.AppImage";
    name = "${name}.AppImage";
    hash = "sha256-c0ivgA0y9UiSTJadlizdkOM7FKfdRq+nsenuYf8fjEQ=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in appimageTools.wrapType2 {
  inherit pname version src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/ente.desktop $out/share/applications/ente.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share

    substituteInPlace $out/share/applications/ente.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=ente-desktop'
  '';

  meta = with lib; {
    description =
      "The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.";
    homepage = "https://github.com/ente-io/ente/tree/main/desktop";
    changelog =
      "https://github.com/ente-io/photos-desktop/releases/tag/v${version}";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
