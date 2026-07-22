#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-menu}"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "VPN" "$1"
    else
        printf 'VPN: %s\n' "$1" >&2
    fi
}

refresh() {
    pkill -RTMIN+11 -x waybar 2>/dev/null || true
}

open_editor() {
    if command -v nm-connection-editor >/dev/null 2>&1; then
        nm-connection-editor >/dev/null 2>&1 &
    else
        notify "nm-connection-editor не найден"
        return 1
    fi
}

case "$mode" in
    editor)
        open_editor
        exit
        ;;
    menu)
        ;;
    *)
        echo "usage: $0 {menu|editor}" >&2
        exit 2
        ;;
esac

command -v nmcli >/dev/null 2>&1 || {
    notify "nmcli не найден"
    exit 1
}

command -v rofi >/dev/null 2>&1 || {
    notify "Rofi не найден"
    exit 1
}

declare -A active=()
declare -a connections=()

while IFS= read -r name; do
    [[ -n "$name" ]] && active["$name"]=1
done < <(
    nmcli \
        -t \
        -e no \
        -f NAME \
        connection show --active \
        2>/dev/null || true
)

while IFS=: read -r name kind; do
    [[ -n "$name" ]] || continue

    case "$kind" in
        vpn|wireguard)
            connections+=("$name")
            ;;
    esac
done < <(
    nmcli \
        -t \
        -e no \
        -f NAME,TYPE \
        connection show \
        2>/dev/null || true
)

declare -a menu=()

for name in "${connections[@]}"; do
    if [[ -n "${active[$name]:-}" ]]; then
        menu+=("󰌿  Отключить: $name")
    else
        menu+=("󰌾  Подключить: $name")
    fi
done

menu+=("󰢹  Открыть редактор соединений")

choice="$(
    printf '%s\n' "${menu[@]}" |
        rofi -dmenu -i -p "VPN"
)" || exit 0

case "$choice" in
    *"Отключить: "*)
        name="${choice#*Отключить: }"
        nmcli connection down id "$name"
        refresh
        notify "Отключено: $name"
        ;;

    *"Подключить: "*)
        name="${choice#*Подключить: }"
        nmcli connection up id "$name"
        refresh
        notify "Подключено: $name"
        ;;

    *"Открыть редактор"*)
        open_editor
        ;;
esac
