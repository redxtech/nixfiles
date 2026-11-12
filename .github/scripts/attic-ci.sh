#!/usr/bin/env bash
set -euo pipefail

: "${ATTIC_TOKEN:?Set ATTIC_TOKEN to a token with pull and push permissions on main}"
results=()
while [[ "${1:-}" == --result ]]; do
  results+=("${2:?Provide a result path}")
  shift 2
done
[[ $# -gt 0 ]] || { echo 'Provide a build command' >&2; exit 2; }
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

umask 077
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/config/attic" "$work/roots"
endpoint="https://attic.colobus-pirate.ts.net/"
printf '%s' "$ATTIC_TOKEN" > "$work/config/attic/token"
cat > "$work/config/attic/config.toml" <<EOF
default-server = "ci"
[servers.ci]
endpoint = "$endpoint"
token-file = "$work/config/attic/token"
EOF

queue="$work/paths"
touch "$queue"
original_hook="$(nix config show --json | jq -r '."post-build-hook".value')"
# expand output variables in the daemon's hook, not this process
# shellcheck disable=SC2016
{
  printf '#!%s\nset -euo pipefail\n' "$(command -v bash)"
  if [[ -n "$original_hook" ]]; then
    printf '%q "$@"\n' "$original_hook"
  fi
  # the daemon can invoke hooks concurrently, so lock the shared queue
  printf '(\n  %q 9\n' "$(command -v flock)"
  printf '  read -r -a outputs <<< "${OUT_PATHS:-}"\n'
  # queued outputs must survive automatic GC until the upload finishes
  printf '  for output in "${outputs[@]}"; do\n'
  printf '    %q --add-root %q/"${output##*/}" --indirect --realise "$output" >/dev/null\n' \
    "$(command -v nix-store)" "$work/roots"
  printf '  done\n'
  printf '  if ((${#outputs[@]})); then printf "%%s\\n" "${outputs[@]}" >&9; fi\n'
  printf ') 9>>%q\n' "$queue"
} > "$work/hook"
chmod 700 "$work/hook"

export NIX_CONFIG="${NIX_CONFIG:-}
post-build-hook = $work/hook"
# credentials stay in the temporary client config, not the build environment
unset ATTIC_TOKEN
build_status=0
bash "$script_dir/time-command.sh" "nix command (evaluation, build, and substitution)" "$@" || build_status=$?
if [[ "$build_status" -eq 0 ]]; then
  # a failed Attic upload must not suppress the independent Cachix closure push
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo 'build-succeeded=true' >> "$GITHUB_OUTPUT"
  fi
  if [[ ${#results[@]} -gt 0 ]]; then
    printf '%s\n' "${results[@]}" >> "$queue"
  fi
fi

upload_status=0
if [[ -s "$queue" ]]; then
  # attic follows discovery, so reject a server that would send uploads back through Cloudflare
  if curl --fail --silent --show-error --connect-timeout 10 --max-time 30 \
    --retry 2 "${endpoint}_api/v1/cache-config/main" \
    | jq --exit-status --arg endpoint "$endpoint" '.api_endpoint == $endpoint' > /dev/null; then
    LC_ALL=C sort -u "$queue" | XDG_CONFIG_HOME="$work/config" \
      bash "$script_dir/time-command.sh" "attic upload" attic push ci:main --jobs 2 --stdin \
      || upload_status=$?
  else
    echo 'Attic discovery failed or advertised a different API endpoint. Deploy the Tailscale API endpoint on Quasar.' >&2
    upload_status=1
  fi
fi
if [[ "$upload_status" -ne 0 ]]; then
  echo "Attic upload failed with status $upload_status" >&2
fi
if [[ "$build_status" -ne 0 ]]; then
  exit "$build_status"
fi
exit "$upload_status"
