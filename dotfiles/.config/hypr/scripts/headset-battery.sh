#!/usr/bin/env bash
set -euo pipefail

settings="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/user-settings.sh"
# shellcheck source=/dev/null
[[ -f $settings ]] && source "$settings"
HEADSET_MAC=${HEADSET_MAC:-}
HEADSET_NAME=${HEADSET_NAME:-Bluetooth headset}

if [[ -z ${HEADSET_MAC:-} ]]; then
  printf '%s\n' '{"text":"","tooltip":"MAC-адрес гарнитуры не настроен","class":"unconfigured"}'
  exit 0
fi

status=$(bluetoothctl info "$HEADSET_MAC" 2>/dev/null || true)
if ! grep -q 'Connected: yes' <<<"$status"; then
  printf '%s\n' '{"text":"","tooltip":"Наушники не подключены","class":"disconnected"}'
  exit 0
fi

battery=$(sed -nE 's/.*Battery Percentage:.*\(([0-9]+)\).*/\1/p' <<<"$status" | head -n1)
if [[ ! $battery =~ ^[0-9]+$ ]]; then
  printf '{"text":"","tooltip":"%s подключены; заряд недоступен","class":"connected"}\n' "$HEADSET_NAME"
  exit 0
fi

class=good
(( battery < 50 )) && class=warning
(( battery < 20 )) && class=critical
printf '{"text":" %s%%","tooltip":"%s · %s%%","percentage":%s,"class":"%s"}\n' \
  "$battery" "$HEADSET_NAME" "$battery" "$battery" "$class"
