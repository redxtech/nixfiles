#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash common-updater-scripts curl coreutils jq

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

latestTag=$(curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} \
  "https://api.github.com/repos/beekeeper-studio/ultimate-releases/releases/latest" \
  | jq -r ".tag_name")
latestVersion="$(expr "$latestTag" : 'v\(.*\)')"

latestURL="https://github.com/beekeeper-studio/ultimate-releases/releases/download/v${latestVersion}/Beekeeper-Studio-${latestVersion}.AppImage"
latestHash="$(nix hash convert --hash-algo sha256 --from nix32 "$(nix-prefetch-url "$latestURL")")"

echo "Updating beekeeper-studio-ultimate for x86_64-linux"
sed -i "s/version = \"\(.*\)\";/version = \"${latestVersion}\";/" "$SCRIPT_DIR/default.nix"
sed -i "s/hash = \"\(.*\)\";/hash = \"${latestHash}\";/" "$SCRIPT_DIR/default.nix"
