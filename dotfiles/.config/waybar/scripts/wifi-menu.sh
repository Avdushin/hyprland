#!/usr/bin/env bash
set -Eeuo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send 'Wi-Fi' "$1" || true; }
command -v rofi >/dev/null 2>&1 || { notify 'Rofi is not installed'; exit 1; }
command -v nmcli >/dev/null 2>&1 || { notify 'nmcli is not installed'; exit 1; }

state=$(nmcli -t -f WIFI general 2>/dev/null | head -n1)
if [[ $state == enabled ]]; then
  toggle='󰖪  Disable Wi-Fi'
else
  toggle='󰖩  Enable Wi-Fi'
fi

choice="$({
  printf '%s\n' "$toggle"
  printf '%s\n' '󰤨  Connect to a network'
  printf '%s\n' '󰑐  Rescan networks'
  printf '%s\n' '󰒓  Open connection editor'
} | rofi -dmenu -i -p 'Wi-Fi')" || exit 0

case "$choice" in
  *'Disable Wi-Fi'*) nmcli radio wifi off ;;
  *'Enable Wi-Fi'*) nmcli radio wifi on ;;
  *'Rescan networks'*) nmcli device wifi rescan; notify 'Network list refreshed' ;;
  *'Open connection editor'*) nohup nm-connection-editor >/dev/null 2>&1 & ;;
  *'Connect to a network'*)
    nmcli radio wifi on
    mapfile -t rows < <(nmcli -t --escape no -f SSID,SIGNAL,SECURITY device wifi list --rescan yes | awk -F: 'NF && $1 != "" {print}' | sort -t: -k2,2nr -u)
    ((${#rows[@]})) || { notify 'No Wi-Fi networks were found'; exit 0; }
    selected=$(printf '%s\n' "${rows[@]}" | sed 's/:/  ·  /g' | rofi -dmenu -i -p 'Network') || exit 0
    ssid=${selected%%  ·  *}
    printf -v command_line 'nmcli --ask device wifi connect %q; rc=$?; echo; read -r -p "Press Enter..."; exit $rc' "$ssid"
    alacritty --title 'Wi-Fi connection' -e bash -lc "$command_line"
    ;;
esac

pkill -RTMIN+10 -x waybar 2>/dev/null || true
