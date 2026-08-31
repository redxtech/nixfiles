{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        curl
        fetchurl
        python3
        stdenv
        stdenvNoCC
        ;

      pname = "moshi-hook";
      version = "0.3.16";

      sources = {
        x86_64-linux = {
          os = "Linux";
          arch = "x86_64";
          hash = "sha256-7pb/POvmhkipYxl2Zgr6SnokfPosyMAw2dXsp4TfWpU=";
        };
        aarch64-linux = {
          os = "Linux";
          arch = "arm64";
          hash = "sha256-jfbYPc0aqZxC51FpN/KSSfOo9wTZ2dfuxwP6IoeohmY=";
        };
        x86_64-darwin = {
          os = "Darwin";
          arch = "x86_64";
          hash = "sha256-YIyK9Updet1ObVjOLRtbPqC6U2/Yt+V9lHtfnyROgxE=";
        };
        aarch64-darwin = {
          os = "Darwin";
          arch = "arm64";
          hash = "sha256-FzVQxkN+ZmPb30Nzb8nLyipa+Kz3w9YbLDqXxJY89ZY=";
        };
      };
      source = sources.${stdenv.hostPlatform.system};
      assetName = sourceInfo: "moshi-hook_${sourceInfo.os}_${sourceInfo.arch}.tar.gz";
      assets = lib.mapAttrs (_: assetName) sources;
      updateScript = pkgs.writeShellApplication {
        name = "update-moshi";
        runtimeInputs = [
          curl
          python3
        ];
        text = ''
          packageFile=packages/moshi/package.nix
          version="$(curl --fail --silent --show-error https://cdn.getmoshi.app/hook/latest/version.txt)"
          version="''${version#v}"
          checksums="$(mktemp)"
          trap 'rm -f "$checksums"' EXIT
          curl --fail --silent --show-error \
            "https://cdn.getmoshi.app/hook/v$version/checksums.txt" \
            --output "$checksums"

          python3 - \
            "$packageFile" \
            "$version" \
            "$checksums" \
            ${lib.escapeShellArg (builtins.toJSON assets)} <<'PY'
          import base64
          import json
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version = sys.argv[2]
          checksum_path = pathlib.Path(sys.argv[3])
          assets = json.loads(sys.argv[4])
          checksums = {
              filename: digest
              for digest, filename in (
                  line.split() for line in checksum_path.read_text().splitlines()
              )
          }

          text = path.read_text()
          text, version_replacements = re.subn(
              r'(?m)^(      version = ")[^"]+(";)$',
              rf'\g<1>{version}\g<2>',
              text,
              count=1,
          )
          if version_replacements != 1:
              raise SystemExit(
                  f"expected one version in {path}, replaced {version_replacements}"
              )

          for system, asset in assets.items():
              try:
                  digest = checksums[asset]
              except KeyError as error:
                  raise SystemExit(f"missing checksum for {asset}") from error
              sri_hash = "sha256-" + base64.b64encode(bytes.fromhex(digest)).decode()
              text, replacements = re.subn(
                  rf'({re.escape(system)} = \{{.*?hash = ")[^"]+(";)',
                  rf'\g<1>{sri_hash}\g<2>',
                  text,
                  count=1,
                  flags=re.DOTALL,
              )
              if replacements != 1:
                  raise SystemExit(
                      f"expected one {system} hash in {path}, replaced {replacements}"
                  )

          path.write_text(text)
          PY
        '';
      };
    in
    {
      packages.moshi = stdenvNoCC.mkDerivation {
        inherit pname version;

        src = fetchurl {
          url = "https://cdn.getmoshi.app/hook/v${version}/${assetName source}";
          inherit (source) hash;
        };

        sourceRoot = ".";
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          install -Dm755 moshi-hook $out/bin/moshi-hook
          ln -s moshi-hook $out/bin/moshi

          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          $out/bin/moshi-hook version | grep -F "moshi-hook ${version}"
          $out/bin/moshi version | grep -F "moshi-hook ${version}"

          runHook postInstallCheck
        '';

        passthru.updateScript = lib.getExe updateScript;

        meta = {
          description = "Daemon and CLI that bridges AI coding agents to the Moshi mobile app";
          homepage = "https://getmoshi.app";
          license = lib.licenses.unfree;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "moshi";
          platforms = builtins.attrNames sources;
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      };
    };
}
