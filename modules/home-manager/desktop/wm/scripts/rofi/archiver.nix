{ writeShellApplication, coreutils, nemo-with-extensions, libnotify, tofi
, rofiApp ? tofi, rofiCmd ? "${tofi}/bin/tofi", ... }:

writeShellApplication {
  name = "archiver";

  runtimeInputs = [ coreutils rofiApp nemo-with-extensions libnotify ];

  text = let
    formats = [
      "xz"
      "txz"
      "gz"
      "tgz"
      "bz"
      "tbz"
      "bz2"
      "tbz2"
      "Z"
      "tZ"
      "lzo"
      "tzo"
      "lz"
      "tlz"
      "7z"
      "t7z"
      "tar"
      "zip"
      "lzma"
      "rz"
      "lrz"
    ];
    formatsMulti =
      [ "tgz" "tbz" "tbz2" "tZ" "tzo" "tlz" "t7z" "tar" "zip" "rar" "lhz" ];
  in ''
    # rofi script to encode files
    # usage: encode [files]
    # if multiple files are selected, they will be compressed into a single archive

    # rofi_cmd: wrapper around rofi to set prompt text and size
    rofi_cmd () {
      prompt="$1"
      shift
      ${rofiCmd} --prompt-text "$prompt" "$@"
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

    single_formats="${builtins.concatStringsSep "\\n" formats}" 
    multi_formats="${builtins.concatStringsSep "\\n" formatsMulti}" 

    archive_files() {
      basename="$(basename "$1")"
      dir="$(dirname "$(realpath "$1")")"
      nameNoExt="''${basename%.*}"

      # turn files from $@ into relative paths
      # shellcheck disable=SC2046
      set -- $(for file in "$@"; do relpath "$dir" "$file"; done)

      # choose name for archive
      archive_name=$(echo "$nameNoExt" | rofi_cmd "archive filename: " --require-match false)

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
      pushd "$dir" >/dev/null
      apack "$output" "$@"
      archive_status="$?"
      popd >/dev/null

      if [ $archive_status -eq 0 ]; then
        should_view="$(notify_send "archive created" "archive created at: $output" --action "default=view file")"

        echo "should_view: $should_view"

        [ "$should_view" = "default" ] && nemo "$output" & disown
      else
        notify_send "archive creation failed" "failed to create archive at $output" --icon error
      fi
    }

    archive_files "$@"
  '';
}
