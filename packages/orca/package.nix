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
      version = "1.4.182";

      sources = {
        x86_64-linux = {
          url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
          hash = "sha256-waC5UCpfbAFBBPtRt9Qgcx4d0bzw08Y/IDV+7lL3T2o=";
        };
        aarch64-linux = {
          url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux-arm64.AppImage";
          hash = "sha256-iieOoiWYq4wa56On+flc2bYTiVB8O87tsRa7peeTNGE=";
        };
      };

      src = fetchurl sources.${stdenv.hostPlatform.system};
      updateScript = pkgs.writeShellApplication {
        name = "update-orca";
        runtimeInputs = with pkgs; [
          jq
          nix
          nix-update
          python3
        ];
        text = ''
          packageFile=packages/orca/package.nix
          nix-update --flake --use-github-releases "''${UPDATE_NIX_ATTR_PATH:-orca}"

          version="$(
            python3 - "$packageFile" <<'PY'
          import pathlib
          import re
          import sys

          match = re.search(r'(?m)^      version = "([^"]+)";', pathlib.Path(sys.argv[1]).read_text())
          if match is None:
              raise SystemExit(f"could not find version in {sys.argv[1]}")
          print(match.group(1))
          PY
          )"
          armUrl="https://github.com/stablyai/orca/releases/download/v$version/orca-linux-arm64.AppImage"
          armHash="$(nix store prefetch-file --json "$armUrl" | jq --exit-status --raw-output .hash)"

          python3 - "$packageFile" "$armHash" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          arm_hash = sys.argv[2]
          text = path.read_text()
          text, replacements = re.subn(
              r'(aarch64-linux = \{.*?hash = ")[^"]+(";)',
              rf'\g<1>{arm_hash}\g<2>',
              text,
              count=1,
              flags=re.DOTALL,
          )
          if replacements != 1:
              raise SystemExit(f"expected one aarch64 hash in {path}, replaced {replacements}")
          path.write_text(text)
          PY
        '';
      };
      appimageContents = appimageTools.extract {
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

        passthru.updateScript = lib.getExe updateScript;

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
