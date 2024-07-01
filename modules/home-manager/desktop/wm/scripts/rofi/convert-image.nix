{ writeShellApplication, imagemagick, cinnamon, libnotify, tofi
, rofiCmd ? "${tofi}/bin/tofi", ... }:

writeShellApplication {
  name = "convert-image";

  runtimeInputs = [ imagemagick tofi cinnamon.nemo libnotify ];

  text = let formats = [ "png" "jpg" "webp" "svg" ];
  in ''
    # rofi script to convert images
    # usage: convert-image [file]

    formats="${builtins.concatStringsSep "\\n" formats}" 

    rofi_cmd () {
      ${rofiCmd} --prompt-text "$@" --width=480 --height=360
    }

    # send notification
    notify_send() {
      title="$1"
      body="$2"
      shift 2

      status="$(notify-send "$title" "$body" \
        --icon image-x-generic \
        --app-name "convert-image" \
        --expire-time 10000 \
        "$@")"

      echo "$status"
    }

    convert-image() {
      if [ "$#" -eq 0 ]; then
        notify_send "no file provided" "please provide a file to convert" --icon error
        return 1
      fi

      format=$(echo -e "$formats" | rofi_cmd "target format: ")

      if [ -z "$format" ]; then
        notify_send "no format selected" "please select a format to convert to" --icon error
        return 1
      fi

      # set output filename
      input=$(realpath "$1")

      basename=$(basename "$input")
      dir=$(dirname "$input")
      nameNoExt="''${basename%.*}"

      output="$dir/$nameNoExt.$format"

      echo "converting $input to $output"

      # convert image
      convert "$input" "$output"

      convert_status="$?"

      if [ $convert_status -eq 0 ]; then
        should_view="$(notify_send "image converted" "$basename converted to: $format" --action "default=view image")"
        [ "$should_view" = "default" ] && nemo "$output" & disown
      else
        notify_send "image conversion failed" "failed to convert $basename to $format" --icon error
      fi
    }

    convert-image "$@"
  '';
}

