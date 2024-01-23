{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl, appimageTools ? pkgs.appimageTools }:

let
  baseName = "beekeeper-studio";
  pname = "${baseName}-ultimate";
  version = "4.1.13";
  name = "${pname}-${version}";

  src = fetchurl {
    url =
      "https://github.com/beekeeper-studio/ultimate-releases/releases/download/v${version}/Beekeeper-Studio-Ultimate-${version}.AppImage";
    name = "${pname}-${version}.AppImage";
    sha256 = "sha256-sMfZP4GF+3aaUletYBayBgN1aag0gwZp+/DRMCcen5Q=";
  };

  appimageContents = appimageTools.extractType2 { inherit name src; };
in appimageTools.wrapType2 {
  inherit name src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash ];

  extraInstallCommands = ''
    ln -s $out/bin/${name} $out/bin/${pname}
    install -m 444 -D ${appimageContents}/${baseName}.desktop $out/share/applications/${pname}.desktop
    install -m 444 -D ${appimageContents}/${baseName}.png \
      $out/share/icons/hicolor/512x512/apps/${pname}.png
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = with lib; {
    description =
      "Ultimate Edition of a modern and easy to use SQL client for MySQL, Postgres, SQLite, SQL Server, and more. Linux, MacOS, and Windows";
    homepage = "https://www.beekeeperstudio.io";
    changelog =
      "https://github.com/beekeeper-studio/ultimate-releases/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ milogert alexnortung ];
    platforms = [ "x86_64-linux" ];
  };
}
