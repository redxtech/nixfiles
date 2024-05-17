pctl() {
	# playerctl --player spotify,mpv,firefox "$@"
	playerctl --player playerctld "$@"
}

showIcon() {
	while IFS= read -r; do
		if test "$(pctl status)" == "Playing"; then
			echo "%{T6}󰏤%{T-}"
		else
			echo "%{T6}󰐊%{T-}"
		fi
	done
}

showStatus() {
	while IFS= read -r status; do
		[ -z "$status" ] || [ "$status" == " - " ] && continue

		printf '%s\n' "$status"
	done
}

main() {
	case "$1" in
	status)
		pctl --follow metadata --format '{{artist}} - {{title}}' | showStatus
		;;
	icon)
		pctl --follow status | showIcon
		;;
	play-pause)
		pctl play-pause
		;;
	next)
		pctl next
		;;
	prev)
		pctl previous
		;;
	*)
		echo "Usage: $0 {status|play-pause|next|prev}"
		exit 1
		;;
	esac
}

main "$@"
