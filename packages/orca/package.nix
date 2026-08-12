{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        appimageTools
        fetchurl
        makeWrapper
        stdenv
        util-linux
        xvfb
        ;

      pname = "orca-ide";
      version = "1.4.180";

      sources = {
        x86_64-linux = {
          url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
          hash = "sha256-rztuamf8w80DTKRp/47h0iSxpuLfYhX9hFKv0P2Okqs=";
        };
        aarch64-linux = {
          url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux-arm64.AppImage";
          hash = "sha256-nECNc6/U0TK/dLVXQaWqDjD7FmcJzRsRsyNHvyNTYxg=";
        };
      };

      src = fetchurl sources.${stdenv.hostPlatform.system};
      appimageContents = appimageTools.extractType2 {
        inherit pname version src;
      };

      orca = appimageTools.wrapType2 {
        inherit pname version src;

        nativeBuildInputs = [ makeWrapper ];

        # Orca starts Xvfb itself in serve mode when DISPLAY is unset. util-linux
        # supplies unshare, which AppRun uses to detect Chromium sandbox support.
        extraPkgs = _pkgs: [
          util-linux
          xvfb
        ];

        extraInstallCommands = ''
          install -Dm644 ${appimageContents}/orca-ide.desktop \
            $out/share/applications/orca-ide.desktop
          substituteInPlace $out/share/applications/orca-ide.desktop \
            --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=orca-ide %U'
          cp -r ${appimageContents}/usr/share/icons $out/share/

          makeWrapper $out/bin/orca-ide $out/bin/orca-server \
            --add-flags serve \
            --set LIBGL_ALWAYS_SOFTWARE 1
        '';

        passthru.updateScript = pkgs.nix-update-script { };

        meta = {
          description = "ADE for working with a fleet of parallel coding agents";
          homepage = "https://github.com/stablyai/orca";
          changelog = "https://github.com/stablyai/orca/releases/tag/v${version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "orca-ide";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        };
      };
    in
    {
      packages = { inherit orca; };

      apps = {
        orca = {
          type = "app";
          program = lib.getExe orca;
          meta.description = "Run the Orca desktop app";
        };

        orca-server = {
          type = "app";
          program = lib.getExe' orca "orca-server";
          meta.description = "Run the Orca headless server";
        };
      };
    };
}
