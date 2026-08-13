#!/usr/bin/env bash
set -euo pipefail

package_file="${1:-packages/plex-pass/package.nix}"
plex_api_json="$(curl --fail --silent --show-error https://plex.tv/api/downloads/5.json)"
version="$(jq --exit-status --raw-output '.computer.Linux.version' <<<"$plex_api_json")"
url="$(
  jq --exit-status --raw-output \
    '.computer.Linux.releases[] | select(.distro == "debian") | select(.build | contains("x86_64")) | .url' \
    <<<"$plex_api_json"
)"
hash="$(nix store prefetch-file --json "$url" | jq --exit-status --raw-output .hash)"

python3 - "$package_file" "$version" "$url" "$hash" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
version, url, source_hash = sys.argv[2:]
text = path.read_text()
replacements = []
for pattern, replacement in (
    (r'(?m)^(          version = ")[^"]+(";)$', rf'\g<1>{version}\g<2>'),
    (r'(?m)^(            url = ")[^"]+(";)$', rf'\g<1>{url}\g<2>'),
    (r'(?m)^(            hash = ")[^"]+(";)$', rf'\g<1>{source_hash}\g<2>'),
):
    text, count = re.subn(pattern, replacement, text, count=1)
    replacements.append(count)
if replacements != [1, 1, 1]:
    raise SystemExit(f"unexpected replacements in {path}: {replacements}")
path.write_text(text)
PY
