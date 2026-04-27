# rofi script to show the powermenu
# usage: powermenu

lock=" Lock"
sleep=" Sleep"
hibernate=" Hibernate"
logout="󰍃 Logout"
restart=" Restart"
windows=" Reboot to Windows"
shutdown="⏻ Shutdown"
cancel="󰕌 Cancel"

options="$lock\n$sleep\n$hibernate\n$logout\n$restart\n$windows\n$shutdown\n$cancel"

confirm() {
	confirmation="$(echo -e "Yes\nNo" | fuzzel --dmenu --prompt "Are you sure? ")"

	if [[ "$confirmation" != "Yes" ]]; then
		exit 0
	fi
}

answer="$(echo -e "$options" | fuzzel --dmenu --prompt "Action: ")"

case $answer in
"$lock")
	playerctl pause
	noctalia-shell ipc call lockScreen lock
	;;
"$sleep")
	confirm
	sleep 1 && niri msg action power-off-monitors
	;;
"$hibernate")
	confirm
	sleep 1 && systemctl hibernate
	;;
"$logout")
	confirm
	niri msg action quit
	;;
"$restart")
	confirm
	systemctl reboot
	;;
"$windows")
	confirm
	systemctl reboot --boot-loader-entry=auto-windows
	;;
"$shutdown")
	confirm
	systemctl poweroff
	;;
"$cancel")
	exit 0
	;;
esac
