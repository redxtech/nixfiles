restore_name=
restore_target=

restore_mode() {
  if [[ -z "$restore_name" ]]; then
    return 0
  fi

  local name=$restore_name target=$restore_target
  restore_name=
  if ! niri msg output "$name" mode "$target"; then
    printf 'reset-monitors: failed to restore %s to %s\n' "$name" "$target" >&2
    return 1
  fi
}

# keep cleanup in the main shell so a signal to the command also restores its output
trap 'restore_mode || exit 1' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

outputs=$(niri msg --json outputs)
status=0

reset_monitor() {
  local name=$1 width=$2 height=$3 rate=$4
  local modes temporary target

  if ! modes=$(jq -r \
    --arg name "$name" \
    --argjson width "$width" \
    --argjson height "$height" \
    --argjson rate "$rate" '
      def mode: "\(.width)x\(.height)@\(.refresh_rate / 1000)";
      .[$name] as $output
      | if $output == null or $output.current_mode == null then
          empty
        else
          $output.modes[$output.current_mode] as $current
          | [$output.modes[] | select(.width == $width and .height == $height)] as $available
          | ($available | min_by((.refresh_rate - $rate * 1000) | fabs)) as $target
          | if $target == null or (($target.refresh_rate - $rate * 1000) | fabs) > 1000 then
              error("configured mode is not available")
            else
              ($available | map(select(.refresh_rate != $target.refresh_rate
                  and (.width != $current.width or .height != $current.height
                    or .refresh_rate != $current.refresh_rate)))
                | min_by((.refresh_rate - 60000) | fabs)) as $temporary
              | if $temporary == null then
                  error("no alternate refresh rate is available")
                else
                  [($temporary | mode), ($target | mode)] | @tsv
                end
            end
        end
    ' <<< "$outputs"); then
    printf 'reset-monitors: cannot reset %s\n' "$name" >&2
    return 1
  fi

  if [[ -z "$modes" ]]; then
    printf 'reset-monitors: skip disconnected or disabled output %s\n' "$name"
    return 0
  fi

  IFS=$'\t' read -r temporary target <<< "$modes"

  restore_name=$name
  restore_target=$target
  printf 'reset-monitors: %s: %s -> %s\n' "$name" "$temporary" "$target"
  if ! niri msg output "$name" mode "$temporary"; then
    restore_mode || return 1
    return 1
  fi
  if ! sleep 2; then
    restore_mode || return 1
    return 1
  fi
  restore_mode
}
