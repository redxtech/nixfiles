{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.deadlock-mod-manager = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "deadlock-mod-manager";
        version = "2.3.0";

        src = pkgs.fetchurl {
          url = "https://github.com/deadlock-mod-manager/deadlock-mod-manager/releases/download/v${finalAttrs.version}/Deadlock.Mod.Manager_${finalAttrs.version}_amd64.deb";
          hash = "sha256-LP5Apu9X67MGp450WNrWx9ICHOd1NjH42JhehpFZH5Q=";
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.desktop-file-utils
          pkgs.dpkg
          pkgs.wrapGAppsHook3
        ];

        buildInputs = [
          pkgs.cairo
          pkgs.dbus
          pkgs.gdk-pixbuf
          pkgs.glib
          pkgs.glib-networking
          pkgs.gtk3
          pkgs.libsoup_3
          pkgs.openssl
          pkgs.stdenv.cc.cc.lib
          pkgs.webkitgtk_4_1
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
        ];

        unpackPhase = ''
          runHook preUnpack
          dpkg-deb -x "$src" .
          runHook postUnpack
        '';

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p "$out"
          cp -r usr/bin usr/share "$out/"
          substituteInPlace "$out/share/applications/Deadlock Mod Manager.desktop" \
            --replace-fail 'Categories=' 'Categories=Game;' \
            --replace-fail 'Exec=deadlock-mod-manager' "Exec=$out/bin/deadlock-mod-manager %u" \
            --replace-fail 'x-scheme-handler/dlmm' 'x-scheme-handler/dlmm;'

          runHook postInstall
        '';

        preFixup = ''
          gappsWrapperArgs+=(
            --set FONTCONFIG_FILE "${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
            --set DISABLE_UPDATE_DESKTOP_DATABASE 1
            --prefix PATH : ${lib.makeBinPath [ pkgs.desktop-file-utils ]}
            --add-flags "--disable-auto-update"
          )
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          desktop-file-validate "$out/share/applications/Deadlock Mod Manager.desktop"
          test -x "$out/bin/deadlock-mod-manager"
          test -s "$out/share/icons/hicolor/128x128/apps/deadlock-mod-manager.png"
          test "$("$out/bin/deadlock-mod-manager" --version)" = \
            "deadlock-mod-manager ${finalAttrs.version}"

          runHook postInstallCheck
        '';

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          description = "Mod manager for the Valve game Deadlock";
          homepage = "https://github.com/deadlock-mod-manager/deadlock-mod-manager";
          changelog = "https://github.com/deadlock-mod-manager/deadlock-mod-manager/releases/tag/v${finalAttrs.version}";
          license = lib.licenses.gpl3Plus;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "deadlock-mod-manager";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      });
    };
}
