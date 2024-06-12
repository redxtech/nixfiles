{ lib, fetchurl, appimageTools, ... }:

let
  pname = "obsidian-smart-connect";
  version = "1.1.56";
  name = "${pname}-${version}";

  src = fetchurl {
    url =
      "https://github.com/brianpetro/smart-connect/releases/download/v${version}/Smart-Connect-Setup-linux-x86_64.AppImage";
    name = "${name}.AppImage";
    hash = "sha256-DA9zBxD2Mt1iPXXnxJxa02lAgJ4oQUnzS3e13ALW28c=";
  };

  appimageContents = appimageTools.extractType2 { inherit name src; };
in appimageTools.wrapType2 {
  inherit name src;

  multiArch = false; # no 32bit needed
  extraPkgs = pkgs:
    appimageTools.defaultFhsEnvArgs.multiPkgs pkgs ++ [ pkgs.bash ];

  extraInstallCommands = ''
    ln -s $out/bin/${name} $out/bin/${pname}

    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp -av ${appimageContents}/usr/share/icons/hicolor/0x0/apps/*.png $out/share/icons/hicolor/512x512/apps

    install -m 444 -D ${appimageContents}/smart-connect.desktop $out/share/applications/smart-connect.desktop

    substituteInPlace $out/share/applications/smart-connect.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname}'
  '';

  meta = with lib; {
    description =
      "App that allows use of local models for embedding in Obsidian";
    homepage = "https://github.com/brianpetro/smart-connect";
    # license = licenses.unfree;
    platforms = platforms.all;
    maintainers = [ maintainers.redxtech ];
  };
}
