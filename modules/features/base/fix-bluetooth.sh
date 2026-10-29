#!/usr/bin/env bash

set -euo pipefail

device="BC:87:FA:26:3B:97"
action="${1:-reconnect}"

case "$action" in
  reconnect)
    bluetoothctl disconnect "$device"
    sleep 2
    bluetoothctl connect "$device"
    ;;
  reset)
    bluetoothctl power off
    sleep 2
    bluetoothctl power on
    sleep 2
    bluetoothctl connect "$device"
    ;;
  restart)
    bluetoothctl disconnect "$device"
    sudo systemctl restart bluetooth
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 2
    bluetoothctl connect "$device"
    ;;
  *)
    echo "Usage: $0 [reconnect|reset|restart]" >&2
    exit 2
    ;;
esac
