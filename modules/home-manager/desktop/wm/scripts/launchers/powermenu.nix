{ writeShellApplication, coreutils, hyprland, tofi, systemd, playerctl, ... }:

writeShellApplication {
  name = "powermenu";

  runtimeInputs = [ coreutils hyprland tofi systemd playerctl ];

  text = ''
    lock=" Lock"
    sleep=" Sleep"
    logout="󰍃 Logout"
    restart=" Restart"
    shutdown="⏻ Shutdown"
    cancel="󰕌 Cancel"

    options="$lock\n$sleep\n$logout\n$restart\n$shutdown\n$cancel"

    confirm() {
    	confirmation="$(echo -e "Yes\nNo" | tofi)"

    	if [[ "$confirmation" != "Yes" ]]; then
    		exit 0
    	fi
    }

    answer="$(echo -e "$options" | tofi)"

    case $answer in
    "$lock")
    	playerctl pause
    	# hyprlock lock
    	;;
    "$sleep")
    	confirm
    	sleep 1 && hyprctl dispatch dpms off
      # TODO: suspending?
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
