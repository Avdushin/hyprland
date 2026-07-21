#!/usr/bin/env bash
set -Eeuo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send 'Bluetooth' "$1" || true; }
command -v rofi >/dev/null 2>&1 || { notify 'Rofi is not installed'; exit 1; }
command -v bluetoothctl >/dev/null 2>&1 || { notify 'bluetoothctl is not installed'; exit 1; }

powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}')
list_paired() { bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices 2>/dev/null || true; }

build_menu() {
  if [[ $powered == yes ]]; then
    printf '%s\n' '  Disable Bluetooth' '󰂯  Scan for devices'
    while read -r _ mac name; do
      [[ -n ${mac:-} ]] || continue
      connected=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/ {print $2; exit}')
      marker=' '
      [[ $connected == yes ]] && marker='●'
      printf '%s  %s  [%s]\n' "$marker" "$name" "$mac"
    done < <(list_paired)
  else
    printf '%s\n' '  Enable Bluetooth'
  fi
}

choice=$(build_menu | rofi -dmenu -i -p 'Bluetooth' -matching fuzzy) || exit 0
[[ -n $choice ]] || exit 0

case "$choice" in
  *'Enable Bluetooth') bluetoothctl power on ;;
  *'Disable Bluetooth') bluetoothctl power off ;;
  *'Scan for devices')
    bluetoothctl power on >/dev/null 2>&1 || true
    bluetoothctl --timeout 8 scan on >/dev/null 2>&1 || true
    notify 'Scan completed. Open Blueman to pair a new device.'
    command -v blueman-manager >/dev/null 2>&1 && blueman-manager >/dev/null 2>&1 &
    ;;
  *)
    mac=$(grep -oE '\[[0-9A-Fa-f:]{17}\]' <<<"$choice" | tr -d '[]')
    [[ -n $mac ]] || exit 0
    connected=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/ {print $2; exit}')
    if [[ $connected == yes ]]; then
      bluetoothctl disconnect "$mac"
    else
      bluetoothctl connect "$mac" || {
        bluetoothctl pair "$mac" || true
        bluetoothctl trust "$mac" || true
        bluetoothctl connect "$mac"
      }
    fi
    ;;
esac
