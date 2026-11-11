#!/usr/bin/env bash
set -euo pipefail

config="${1:?Provide the server configuration}"
endpoint="${2:?Provide the local API endpoint}"
key_file="${3:?Provide the cache signing key file}"
public_key="${4:?Provide the pinned public key}"

if [[ "$(nix --extra-experimental-features nix-command key convert-secret-to-public < "$key_file" 2>/dev/null)" != "$public_key" ]]; then
  echo 'The SOPS cache signing key does not match the pinned public key' >&2
  exit 1
fi

umask 077
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
atticadm -f "$config" make-token --sub cache-bootstrap --validity 5m \
  --pull main --create-cache main --configure-cache main --configure-cache-retention main \
  > "$work/token"
# keep the token and private key out of process arguments and logs
printf 'header = "Authorization: Bearer %s"\n' "$(< "$work/token")" > "$work/curl.conf"

request() {
  local method="$1"
  shift
  curl --disable --silent --show-error --noproxy '*' --connect-timeout 2 --max-time 5 \
    --config "$work/curl.conf" --header 'Content-Type: application/json' \
    --output "$work/response" --write-out '%{http_code}' --request "$method" \
    "$@" "$endpoint/_api/v1/cache-config/main"
}

check_ok() {
  [[ "$1" == 200 ]] || { echo "Attic $2 failed with HTTP $1" >&2; exit 1; }
}

status="$(request GET --retry 60 --retry-delay 1 --retry-connrefused --retry-max-time 60)"
jq -n '{is_public: true, store_dir: "/nix/store", priority: 41,
  upstream_cache_key_names: ["cache.nixos.org-1", "nix-community.cachix.org-1"]}' > "$work/desired"
case "$status" in
  404)
    jq --rawfile key "$key_file" '. + {keypair: {Keypair: ($key | rtrimstr("\n"))}}' \
      "$work/desired" > "$work/create"
    check_ok "$(request POST --data-binary "@$work/create")" 'cache creation'
    check_ok "$(request GET)" 'cache lookup'
    ;;
  200) ;;
  *) echo "Attic cache lookup failed with HTTP $status" >&2; exit 1 ;;
esac

# never rotate a key that clients already trust
if ! jq -e --arg key "$public_key" '.public_key == $key' "$work/response" >/dev/null; then
  echo 'The existing cache signing key does not match the pinned public key' >&2
  exit 1
fi

# clear an old per-cache override so retention follows the native server setting
jq '. + {retention_period: "Global"}' "$work/desired" > "$work/update"
check_ok "$(request PATCH --data-binary "@$work/update")" 'cache configuration'
