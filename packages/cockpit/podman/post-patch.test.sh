#!/usr/bin/env bash
set -euo pipefail

# use the release Makefile so upstream stamp changes fail this check
source_path="${1:?expected source path}"
post_patch="${2:?expected postPatch script}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cp -a "$source_path/." "$workdir/"
chmod -R u+w "$workdir"
cd "$workdir"
bash -euc "$post_patch"

# query mode must not schedule frontend rebuilding or execute build steps
make --question all
printf 'Release frontend remains up to date after postPatch.\n'
