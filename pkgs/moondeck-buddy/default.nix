{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl, appimageTools ? pkgs.appimageTools }:

let
  pname = "moondeck-buddy";
  version = "1.6.1";
  name = "${pname}-${version}";

  src = fetchurl {
    url =
      "https://github.com/FrogTheFrog/${pname}/releases/download/v${version}/MoonDeckBuddy-${version}-x86_64.AppImage";
    hash = "sha256-FteDRbjv4YTuLkdUxSrusXgNm0xpuqN+EAvjSGAq4rY=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in appimageTools.wrapType2 {
  inherit pname version src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash pkgs.steam ];

  extraInstallCommands = ''
    install -m 555 -D ${appimageContents}/usr/bin/MoonDeckStream $out/bin/moondeck-stream-${version}

    ln -s $out/bin/moondeck-stream-${version} $out/bin/moondeck-stream

    install -m 444 -D ${appimageContents}/MoonDeckBuddy.desktop $out/share/applications/${pname}.desktop

    for size in 16 32 48 64 128 256; do
      install -m 444 -D ${appimageContents}/app.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
    done

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Icon=app' 'Icon=${pname}' \
      --replace-fail 'Exec=MoonDeckBuddy' 'Exec=${pname}'
  '';

  meta = with lib; {
    description = "Helper to work with moonlight on a steamdeck";
    homepage = "https://github.com/FrogTheFrog/moondeck-buddy";
    changelog =
      "https://github.com/FrogTheFrog/${pname}/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
    platforms = [ "x86_64-linux" ];
  };
}
