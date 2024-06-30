{ writeShellApplication, atool, ... }:

writeShellApplication {
  name = "unarchiver";

  runtimeInputs = [ atool ];

  text = ''
    # script to unarchive files using atool
    # usage: unarchive [file]

    unarchive_file() {
      if [ "$#" -eq 0 ]; then
        notify-send "no file provided" "please provide a file to unpack" \
        --icon archive-extract \
        --app-name "unarchiver" \
        --expire-time 10000
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

      timeout="10000" # 10 seconds

      if [ $extract_status -eq 0 ]; then
        should_view="$(notify-send "file extracted" "$basename extracted" \
        --icon archive-extract \
        --app-name "unarchiver" \
        --expire-time "$timeout" \
        --action "default=view result")"

        if [ "$should_view" = "default" ]; then
          nemo "$nameNoExt"
        fi
      else
        notify-send "archive unpacking failed" "failed to extract $basename to $dir" \
        --icon error \
        --app-name "unarchiver" \
        --expire-time "$timeout"
      fi
    }

    unarchive_file "$@"
  '';
}

