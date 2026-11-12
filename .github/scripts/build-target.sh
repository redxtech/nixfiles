#!/usr/bin/env bash
set -euo pipefail

target="${1:?Provide a flake target}"
result="${2:?Provide a result path}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# each target evaluates independently so system errors cannot block package builds
bash "$script_dir/time-command.sh" "evaluation" \
  nix eval "${target}.drvPath" --raw --no-update-lock-file > /dev/null
# keep flake output selection unchanged and reuse Nix's evaluation cache
bash "$script_dir/time-command.sh" "build and substitution (includes cached evaluation)" \
  nix build "$target" --no-update-lock-file --out-link "$result" --print-build-logs
