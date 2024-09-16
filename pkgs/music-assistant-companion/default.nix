{ lib, fetchurl, appimageTools }:

let
  pname = "music-assistant-companion";
  version = "0.0.72";

  src = fetchurl {
    url =
      "https://github.com/music-assistant/companion/releases/download/v${version}/Music.Assistant.Companion_${version}_amd64.AppImage";
    name = "${pname}-${version}.AppImage";
    hash = "sha256-eDAj+kGHtE2rHJ+bEzYYZ/6mJZlwXqX5FryknQ7Ohtg=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in appimageTools.wrapType2 {
  inherit pname version src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash ];

  extraInstallCommands = ''
    ln -s ${appimageContents}/usr/bin/squeezelite $out/bin/squeezelite
    ln -s ${appimageContents}/usr/lib $out/lib
    cp -r ${appimageContents}/usr/share $out/share
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
