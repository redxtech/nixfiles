main() {
	local player="${1:-spotify}"

	playerctl --player="$player" metadata |
		rg 'xesam:url' |
		choose 2 |
		tr -d '\n' |
		xclip -selection clipboard
}

main "$@"
