# rofi script to encode files
# usage: encode [files]
# if multiple files are selected, they will be compressed into a single archive

# rofi_cmd: wrapper around rofi to set prompt text and size
rofi_cmd() {
	prompt="$1"
	shift
	fuzzel --dmenu --prompt "$prompt" "$@"
}

# get relative path of $2 from $1
relpath() {
	realpath -s --relative-to="$1" "$2"
}

# send notification
notify_send() {
	title="$1"
	body="$2"
	shift 2

	status="$(notify-send "$title" "$body" \
		--icon archive \
		--app-name "archiver" \
		--expire-time 10000 \
		"$@")"

	echo "$status"
}

single_formats="xz\ntxz\ngz\ntgz\nbz\ntbz\nbz2\ntbz2\nZ\ntZ\nlzo\ntzo\nlz\ntlz\n7z\nt7z\ntar\nzip\nlzma\nrz\nlrz"
multi_formats="tgz\ntbz\ntbz2\ntZ\ntzo\ntlz\nt7z\ntar\nzip\nrar\nlhz"

archive_files() {
	basename="$(basename "$1")"
	dir="$(dirname "$(realpath "$1")")"
	nameNoExt="${basename%.*}"

	# turn files from $@ into relative paths
	# shellcheck disable=SC2046
	set -- $(for file in "$@"; do relpath "$dir" "$file"; done)

	# choose name for archive
	archive_name=$(echo "$nameNoExt" | rofi_cmd "archive filename: ")

	# if more than one arg is passed, choose a multi format
	if [ $# -gt 1 ]; then
		formats="$multi_formats"
	else
		formats="$single_formats"
	fi

	format=$(echo -e "$formats" | rofi_cmd "select archive format: ")

	if [ -z "$archive_name" ] || [ -z "$format" ]; then
		notify_send "archive creation failed" "no archive name or format selected" --icon "error"
		return 1
	fi

	# set output filename
	output="$dir/$archive_name.$format"
	echo "output: $output"

	# compress files
	pushd "$dir" >/dev/null || exit 1
	apack "$output" "$@"
	archive_status="$?"
	popd >/dev/null || exit 1

	if [ $archive_status -eq 0 ]; then
		should_view="$(notify_send "archive created" "archive created at: $output" --action "default=view file")"

		echo "should_view: $should_view"

		[ "$should_view" = "default" ] && nemo "$output" &
		disown
	else
		notify_send "archive creation failed" "failed to create archive at $output" --icon error
	fi
}

archive_files "$@"
