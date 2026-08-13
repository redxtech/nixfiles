{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs) stdenv fetchurl;

      version = "2.1.0";
      sources = {
        x86_64-linux = {
          arch = "x64";
          hash = "sha256-UW6faT7KTJjTInuSnmWblNYXDTmBS+5cFr0GlxMWvzU=";
        };
        aarch64-linux = {
          arch = "arm64";
          hash = "sha256-NktilO3P34knaN8I8V+mFusOoJxVjtZD30Dj657N5Lg=";
        };
      };
      source = sources.${stdenv.hostPlatform.system};
      updateScript = pkgs.writeShellApplication {
        name = "update-vaulted";
        runtimeInputs = with pkgs; [
          curl
          jq
          nix
          python3
        ];
        text = ''
          packageFile=packages/vaulted/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/woosal1337/vaulted/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"
          x86Hash="$(
            nix store prefetch-file --json \
              "https://github.com/woosal1337/vaulted/releases/download/$tag/vaulted-$tag-linux-x64.tar.gz" \
              | jq --exit-status --raw-output .hash
          )"
          armHash="$(
            nix store prefetch-file --json \
              "https://github.com/woosal1337/vaulted/releases/download/$tag/vaulted-$tag-linux-arm64.tar.gz" \
              | jq --exit-status --raw-output .hash
          )"

          python3 - "$packageFile" "$version" "$x86Hash" "$armHash" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version, x86_hash, arm_hash = sys.argv[2:]
          text = path.read_text()

          text, version_replacements = re.subn(
              r'(?m)^(      version = ")[^"]+(";)$',
              rf'\g<1>{version}\g<2>',
              text,
              count=1,
          )
          text, x86_replacements = re.subn(
              r'(x86_64-linux = \{.*?hash = ")[^"]+(";)',
              rf'\g<1>{x86_hash}\g<2>',
              text,
              count=1,
              flags=re.DOTALL,
          )
          text, arm_replacements = re.subn(
              r'(aarch64-linux = \{.*?hash = ")[^"]+(";)',
              rf'\g<1>{arm_hash}\g<2>',
              text,
              count=1,
              flags=re.DOTALL,
          )
          if (version_replacements, x86_replacements, arm_replacements) != (1, 1, 1):
              raise SystemExit(
                  f"unexpected replacements in {path}: "
                  f"version={version_replacements}, x86={x86_replacements}, arm={arm_replacements}"
              )
          path.write_text(text)
          PY
        '';
      };
      vaulted-unwrapped = stdenv.mkDerivation {
        pname = "vaulted-unwrapped";
        inherit version;

        src = fetchurl {
          url = "https://github.com/woosal1337/vaulted/releases/download/v${version}/vaulted-v${version}-linux-${source.arch}.tar.gz";
          inherit (source) hash;
        };

        sourceRoot = ".";
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp vaulted $out/bin/
          cp -r prebuilds $out/bin/

          runHook postInstall
        '';
      };
    in
    {
      packages.vaulted =
        (pkgs.buildFHSEnv {
          name = "vaulted";
          runScript = lib.getExe' vaulted-unwrapped "vaulted";
          meta = {
            description = "Local-first secrets manager for AI coding agents";
            homepage = "https://vaulted.chele.bi";
            changelog = "https://github.com/woosal1337/vaulted/releases/tag/v${version}";
            license = lib.licenses.mit;
            mainProgram = "vaulted";
            platforms = builtins.attrNames sources;
          };
        }).overrideAttrs
          (oldAttrs: {
            inherit version;
            passthru = (oldAttrs.passthru or { }) // {
              updateScript = lib.getExe updateScript;
            };
          });
    };
}
