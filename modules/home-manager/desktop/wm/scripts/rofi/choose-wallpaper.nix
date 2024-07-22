{ writeShellApplication, swww, findutils, libnotify, fuzzel
, rofiCmd ? "${fuzzel}/bin/fuzzel", ... }:

writeShellApplication {
  name = "choose-wallpaper";

  runtimeInputs = [ swww findutils libnotify ];
  excludeShellChecks = [ "SC2162" ];

  text = ''
    # rofi script to choose a wallpaper
    # usage: choose-wallpaper

    wallpaper_dir="$HOME/Pictures/Wallpaper"

    export SWWW_TRANSITION=wipe
    export SWWW_TRANSITION_FPS=144
    export SWWW_TRANSITION_STEP=2
    export SWWW_TRANSITION_ANGLE=210


    rofi_cmd () {
      ${rofiCmd} --dmenu --prompt "$@"
    }

    # send notification
    notify_send() {
      title="$1"
      body="$2"
      shift 2

      status="$(notify-send "$title" "$body" \
        --icon image-x-generic \
        --app-name "choose-wallpaper" \
        --expire-time 3000 \
        "$@")"

      echo "$status"
    }

    wallpaper=$(find "$wallpaper_dir" -maxdepth 1 -type f -printf "%P\n" | rofi_cmd "Choose Wallpaper:")

    if [ -f "$wallpaper_dir/$wallpaper" ]; then
      swww img \
        "$wallpaper_dir/$wallpaper"

      notify-send "Switched wallpaper to $wallpaper!" -i "$wallpaper_dir/$wallpaper"
    fi
  '';
}

