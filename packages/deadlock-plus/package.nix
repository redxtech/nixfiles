{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.deadlock-plus = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "deadlock-plus";
        version = "0.15.0";

        src = pkgs.fetchurl {
          url = "https://github.com/deadlock-plus/deadlock-plus/releases/download/v${finalAttrs.version}/Deadlock-Plus_${finalAttrs.version}_amd64.deb";
          hash = "sha256-9Yki7PA8cGHls7f2IXzg6fC3VTisuDYNgtUVCOp4bUM=";
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
          pkgs.stdenv.cc.cc.lib
          pkgs.webkitgtk_4_1
        ];

        # the tray and X11 overlay libraries are loaded with dlopen
        runtimeDependencies = [
          pkgs.libayatana-appindicator
          pkgs.libx11
          pkgs.libxfixes
        ];

        unpackPhase = ''
          runHook preUnpack
          dpkg-deb -x "$src" .
          runHook postUnpack
        '';

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;
        dontAutoPatchelf = true;

        installPhase = ''
          runHook preInstall

          mkdir -p "$out"
          cp -r usr/bin usr/lib usr/share "$out/"
          substituteInPlace "$out/share/applications/Deadlock+.desktop" \
            --replace-fail 'Categories=' 'Categories=Game;' \
            --replace-fail 'Exec=deadlock-plus' "Exec=$out/bin/deadlock-plus"

          runHook postInstall
        '';

        # keep the bundled Vulkan layer portable for Steam's runtime container
        postFixup = ''
          autoPatchelf "$out/bin"
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          desktop-file-validate "$out/share/applications/Deadlock+.desktop"
          test -x "$out/bin/deadlock-plus"
          test -s "$out/share/icons/hicolor/128x128/apps/deadlock-plus.png"
          cmp usr/lib/deadlock-plus/libdp_frames_layer.so \
            "$out/lib/deadlock-plus/libdp_frames_layer.so"

          runHook postInstallCheck
        '';

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          description = "Companion app for Deadlock with match stats, builds, and Discord presence";
          homepage = "https://github.com/deadlock-plus/deadlock-plus";
          changelog = "https://github.com/deadlock-plus/deadlock-plus/releases/tag/v${finalAttrs.version}";
          license = lib.licenses.gpl3Plus;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "deadlock-plus";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      });
    };
}
