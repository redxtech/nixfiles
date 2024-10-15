{ writeShellApplication, coreutils, hyprland, systemd, playerctl, fuzzel
, rofiApp ? fuzzel, rofiCmd ? "${fuzzel}/bin/fuzzel", ... }:

writeShellApplication {
  name = "powermenu";

  runtimeInputs = [ coreutils hyprland rofiApp systemd playerctl ];

  text = ''
    # rofi script to show the powermenu
    # usage: powermenu

    # rofi_cmd: wrapper around rofi to set prompt text and size
    rofi_cmd () {
      prompt="$1"
      shift
      ${rofiCmd} --dmenu --prompt "$prompt" "$@"
    }

    lock=" Lock"
    sleep=" Sleep"
    hibernate=" Hibernate"
    logout="󰍃 Logout"
    restart=" Restart"
    shutdown="⏻ Shutdown"
    cancel="󰕌 Cancel"

    options="$lock\n$sleep\n$hibernate\n$logout\n$restart\n$shutdown\n$cancel"

    confirm() {
      confirmation="$(echo -e "Yes\nNo" | rofi_cmd "Are you sure? ")"

      if [[ "$confirmation" != "Yes" ]]; then
        exit 0
      fi
    }

    answer="$(echo -e "$options" | rofi_cmd "Action: ")"

    case $answer in
    "$lock")
      playerctl pause
      loginctl lock-session
      ;;
    "$sleep")
      confirm
      sleep 1 && hyprctl dispatch dpms off
      ;;
    "$hibernate")
      confirm
      sleep 1 && systemctl hibernate
      ;;
    "$logout")
      confirm
      hyprctl dispatch exit
      ;;
    "$restart")
      confirm
      systemctl reboot
      ;;
    "$shutdown")
      confirm
      systemctl poweroff
      ;;
    "$cancel")
      exit 0
      ;;
    esac
  '';
}
