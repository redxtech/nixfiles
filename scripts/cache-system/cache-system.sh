#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: nix run .#cache-system -- [hostname]

Build the system from the flake in the current directory and push to quasar:main.
The default hostname is the local hostname, as with nixos-rebuild --flake .#.
This does not use the active system or activate the new system.

Include the built system and its runtime dependencies for activation.
Do not include build-only dependencies.
Try each upload batch up to 3 times, with waits of 5 and 10 seconds.
Use a token with pull and push access to main. Configure the quasar alias in Bash:
  read -rsp 'Attic push token: ' token
  printf '\n'
  attic login quasar https://attic.colobus-pirate.ts.net/ "$token"
  unset token
EOF
}

if [[ $# -eq 1 && ( $1 == --help || $1 == -h ) ]]; then
  usage
  exit 0
fi
if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

host="${1-$(uname -n)}"
if [[ ! $host =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo 'Invalid hostname. Use letters, digits, dots, underscores, or hyphens. Start with a letter or digit.' >&2
  exit 2
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/cache-system.XXXXXXXX")"
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

target=".#nixosConfigurations.\"$host\".config.system.build.toplevel"
printf 'Build %s\n' "$target" >&2
# the system root protects its entire runtime closure until every batch finishes
nix build "$target" --out-link "$work/system"
nix-store --query --requisites "$work/system" > "$work/paths"

printf 'Push the %s system closure to quasar:main\n' "$host" >&2
# attic's time-based stdin batching does not bound SQLite query parameters
while mapfile -t -n 500 batch && ((${#batch[@]})); do
  for attempt in 1 2 3; do
    if printf '%s\n' "${batch[@]}" | attic push quasar:main --stdin --no-closure; then
      break
    else
      upload_status=$?
    fi
    if [[ $attempt -eq 3 ]]; then
      printf 'Upload batch failed after 3 attempts (status %s).\n' "$upload_status" >&2
      exit "$upload_status"
    fi
    delay=$((attempt * 5))
    printf 'Upload batch attempt %s of 3 failed with status %s. Retry in %s seconds.\n' \
      "$attempt" "$upload_status" "$delay" >&2
    sleep "$delay"
  done
done < "$work/paths"
