#!/usr/bin/env bash
set -euo pipefail

phase="${1:?Provide a phase name}"
shift
[[ $# -gt 0 ]] || { echo 'Provide a command' >&2; exit 2; }

start=$SECONDS
status=0
"$@" || status=$?
elapsed=$((SECONDS - start))
printf '%s: %s seconds, exit status %s\n' "$phase" "$elapsed" "$status" >&2

# reporting must not replace the command's exit status
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf '### %s\n\nDuration: %s seconds. Exit status: %s.\n\n' \
    "$phase" "$elapsed" "$status" >> "$GITHUB_STEP_SUMMARY" \
    || echo '::warning::Cannot write the phase summary.' >&2
fi
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  {
    mkdir -p "$RUNNER_TEMP/resource-usage" &&
      printf '%s\t%s\t%s\n' "$phase" "$elapsed" "$status" >> "$RUNNER_TEMP/resource-usage/timings.tsv"
  } || echo '::warning::Cannot write the phase timings.' >&2
fi
exit "$status"
