{ writeShellApplication, atool, nemo-with-extensions, libnotify, ... }:

writeShellApplication {
  name = "unarchiver";

  runtimeInputs = [ atool nemo-with-extensions libnotify ];

  text = ''
    # script to unarchive files using atool
    # usage: unarchive [file]

    # send notification
    notify_send() {
      title="$1"
      body="$2"
      shift 2

      status="$(notify-send "$title" "$body" \
        --icon archive-extract \
        --app-name "unarchiver" \
        --expire-time 10000 \
        "$@")"

      echo "$status"
    }

    unarchive_file() {
      if [ "$#" -eq 0 ]; then
        notify_send "no file provided" "please provide a file to unpack" --icon error
        return 1
      fi

      # get file location
      input=$(realpath "$1")
      basename=$(basename "$input")
      dir=$(dirname "$input")
      nameNoExt="''${input%.*}"

      echo "extracting $basename to $dir..."

      # extract file
      pushd "$dir" >/dev/null
      aunpack "$input"
      extract_status="$?"
      popd >/dev/null

      if [ $extract_status -eq 0 ]; then
        should_view="$(notify_send "file extracted" "$basename extracted" --action "default=view result")"

        [ "$should_view" = "default" ] && nemo "$nameNoExt" & disown
      else
        notify_send "archive unpacking failed" "failed to extract $basename to $dir" --icon error
      fi
    }

    unarchive_file "$@"
  '';
}

