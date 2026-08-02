#!/usr/bin/env bash
set -Eeuo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send 'Wi-Fi' "$1" || true; }
command -v rofi >/dev/null 2>&1 || { notify 'rofi не установлен'; exit 1; }
command -v nmcli >/dev/null 2>&1 || { notify 'nmcli не установлен'; exit 1; }

state=$(nmcli -t -f WIFI general 2>/dev/null | head -n1)
if [[ $state == enabled ]]; then
  toggle='󰖪  Выключить Wi-Fi'
else
  toggle='󰖩  Включить Wi-Fi'
fi

choice="$({
  printf '%s\n' "$toggle"
  printf '%s\n' '󰤨  Подключиться к сети'
  printf '%s\n' '󰑐  Пересканировать сети'
  printf '%s\n' '󰒓  Открыть редактор подключений'
} | rofi -dmenu -i -p 'Wi-Fi')" || exit 0

case "$choice" in
  *'Выключить Wi-Fi'*) nmcli radio wifi off ;;
  *'Включить Wi-Fi'*) nmcli radio wifi on ;;
  *'Пересканировать'*) nmcli device wifi rescan; notify 'Список сетей обновлён' ;;
  *'Открыть редактор'*) nohup nm-connection-editor >/dev/null 2>&1 & ;;
  *'Подключиться'*)
    nmcli radio wifi on
    mapfile -t rows < <(nmcli -t --escape no -f SSID,SIGNAL,SECURITY device wifi list --rescan yes | awk -F: 'NF && $1 != "" {print}' | sort -t: -k2,2nr -u)
    ((${#rows[@]})) || { notify 'Доступные сети не найдены'; exit 0; }
    selected=$(printf '%s\n' "${rows[@]}" | sed 's/:/  ·  /g' | rofi -dmenu -i -p 'Сеть') || exit 0
    ssid=${selected%%  ·  *}
    # Ask for credentials in a visible terminal. Passwords are handled by
    # NetworkManager and are never read or written by this repository.
    printf -v command_line 'nmcli --ask device wifi connect %q; rc=$?; echo; read -r -p "Нажмите Enter..."; exit $rc' "$ssid"
    ghostty --title 'Wi-Fi connection' -e bash -lc "$command_line"
    ;;
esac

pkill -RTMIN+10 -x waybar 2>/dev/null || true
