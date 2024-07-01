{ writeShellApplication, coreutils, ffmpeg_7, libnotify, cinnamon, tofi
, rofiApp ? tofi, rofiCmd ? "${tofi}/bin/tofi", ... }:

writeShellApplication {
  name = "encoder";

  runtimeInputs = [ coreutils ffmpeg_7 libnotify rofiApp cinnamon.nemo ];

  text = let
    presets = [
      # "custom"
      "discord"
      "high"
      "medium"
      "low"
    ];
  in ''
    # rofi script to encode video files
    # usage: encoder [file]

    # rofi_cmd: wrapper around rofi to set prompt text and size
    rofi_cmd () {
      prompt="$1"
      shift
      ${rofiCmd} --prompt-text "$prompt" "$@"
    }

    # send notification
    notify_send() {
      title="$1"
      body="$2"
      shift 2

      status="$(notify-send "$title" "$body" \
        --icon video \
        --app-name "encoder" \
        "$@")"

      echo "$status"
    }

    presets="${builtins.concatStringsSep "\\n" presets}" 

    archive_files() {
      if [ "$#" -eq 0 ]; then
        notify_send "no file provided" "please provide a file to convert" --icon error
        return 1
      fi

      input="$(realpath "$1")"
      basename="$(basename "$input")"
      dir="$(dirname "$input")"
      nameNoExt="''${basename%.*}"

      preset=$(echo -e "$presets" | rofi_cmd "select encode preset: ")

      if [ -z "$preset" ]; then
        notify_send "video encode failed" "no preset selected" --icon "error"
        return 1
      fi

      case $preset in
      discord) # for embedding in discord
        vid_codec="vpx-vp9"
        quality="25"
        quality_args="-crf $quality -b:v 0"
        vid_preset=""
        audio_codec="libopus"
        audio_bitrate="256k"
        container="webm"

        output="$dir/$nameNoExt [discord].$container"
        ;;
      high) # high quality x264 & opus in an mkv
        vid_codec="x264"
        quality="22"
        quality_args="-crf $quality"
        vid_preset="-preset medium"
        audio_codec="libopus"
        audio_bitrate="320k"
        container="mkv"

        output="$dir/$nameNoExt [$vid_codec-$quality-$audio_codec].$container"
        ;;
      medium) # decent quality x265 & opus in an mkv
        vid_codec="x265"
        quality="26"
        quality_args="-crf $quality"
        vid_preset="-preset veryfast"
        audio_codec="libopus"
        audio_bitrate="256k"
        container="mkv"

        output="$dir/$nameNoExt [$vid_codec-$quality-$audio_codec].$container"
        ;;
      low) # conservative quality x265 & opus in an mkv
        vid_codec="x265"
        quality="32"
        quality_args="-crf $quality"
        vid_preset="-preset veryfast"
        audio_codec="libopus"
        audio_bitrate="128k"
        container="mkv"

        output="$dir/$nameNoExt [$vid_codec-$quality-$audio_codec].$container"
        ;;
      *) # custom
        echo "custom preset not implemented yet"
        return 1
      esac

      echo "output: $output"

      # encode the file with ffmpeg
      # shellcheck disable=SC2086
      ffmpeg -i "$input" -c:v "lib$vid_codec" $quality_args $vid_preset -c:a "$audio_codec" -b:a "$audio_bitrate" "$output"

      # get status of encode command
      encode_status="$?"

      # time for notification to stay present
      timeout="120000" # 120 seconds

      # if the encode was successful, send a notification
      if test "$encode_status" = "0"; then
        should_view="$(notify_send "video encoded" "$basename converted to: $vid_codec" --action "default=view video" --expire-time "$timeout")"
        [ "$should_view" = "default" ] && nemo "$output" & disown
      else
        notify_send "video encode failed" "failed to convert $basename to $vid_codec" --icon error
      fi
    }

    archive_files "$@"
  '';
}
