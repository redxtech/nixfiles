{
  perSystem =
    { pkgs, lib, ... }:
    let
      addonId = "nostalgy@opto.one";
      updateScript = pkgs.writeShellApplication {
        name = "update-nostalgy";
        runtimeInputs = [
          pkgs.curl
          pkgs.jq
          pkgs.nix
          pkgs.python3
          pkgs.unzip
        ];
        text = ''
          packageFile=packages/nostalgy/package.nix
          tmpFile="$(mktemp)"
          trap 'rm -f "$tmpFile"' EXIT

          url="$(curl --fail --location --silent --show-error \
            https://addons.thunderbird.net/thunderbird/downloads/latest/nostalgy_ng/latest.xpi \
            --output "$tmpFile" \
            --write-out '%{url_effective}')"
          url="''${url%%\?*}"
          version="$(unzip -p "$tmpFile" manifest.json | jq --exit-status --raw-output .version)"
          hash="$(nix store prefetch-file --json "$url" | jq --exit-status --raw-output .hash)"

          python3 - "$packageFile" "$version" "$url" "$hash" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version, url, source_hash = sys.argv[2:]
          text = path.read_text()
          text, version_replacements = re.subn(
              r'(?m)^(\s+version = ")[^"]+(";)$',
              rf'\g<1>{version}\g<2>',
              text,
              count=1,
          )
          text, url_replacements = re.subn(
              r'(?m)^(\s+url = ")[^"]+(";)$',
              rf'\g<1>{url}\g<2>',
              text,
              count=1,
          )
          text, hash_replacements = re.subn(
              r'(?m)^(\s+hash = ")[^"]+(";)$',
              rf'\g<1>{source_hash}\g<2>',
              text,
              count=1,
          )
          if (version_replacements, url_replacements, hash_replacements) != (1, 1, 1):
              raise SystemExit(
                  f"unexpected replacements in {path}: "
                  f"version={version_replacements}, url={url_replacements}, hash={hash_replacements}"
              )
          path.write_text(text)
          PY
        '';
      };
    in
    {
      packages.nostalgy = pkgs.stdenvNoCC.mkDerivation {
        pname = "nostalgy";
        version = "5.0.5";

        src = pkgs.fetchurl {
          url = "https://addons.thunderbird.net/user-media/addons/_attachments/987740/nostalgy_emails_verwalten_suchen_archivieren-5.0.5-tb.xpi";
          hash = "sha256-2QpSbZT4bR6fch9P1dlO4k5yiqdfn2YQ/ZoOk25Wrd0=";
        };

        dontUnpack = true;

        installPhase = ''
          runHook preInstall

          install -Dm644 "$src" \
            "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"

          runHook postInstall
        '';

        passthru.updateScript = lib.getExe updateScript;

        meta = {
          description = "Keyboard-oriented message filing and folder navigation for Thunderbird";
          homepage = "https://github.com/opto/nostalgy-xpi";
          license = [
            lib.licenses.cc-by-nd-40
            lib.licenses.mpl20
            lib.licenses.zlib
          ];
          platforms = lib.platforms.all;
        };
      };
    };
}
