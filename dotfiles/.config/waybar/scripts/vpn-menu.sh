#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-menu}"
AWG_CONFIG="${AWG_CONFIG:-$HOME/vpn_WG/wg02.conf}"
AWG_IFACE="$(basename "$AWG_CONFIG" .conf)"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send 'VPN' "$1"
    else
        printf 'VPN: %s\n' "$1" >&2
    fi
}

refresh() {
    pkill -RTMIN+11 -x waybar 2>/dev/null || true
}

find_amnezia() {
    local cmd
    for cmd in AmneziaVPN amnezia-vpn amneziavpn; do
        if command -v "$cmd" >/dev/null 2>&1; then
            command -v "$cmd"
            return 0
        fi
    done
    return 1
}

open_amnezia() {
    local app
    if app="$(find_amnezia)"; then
        nohup "$app" >/dev/null 2>&1 &
    else
        notify 'Приложение AmneziaVPN не найдено'
        return 1
    fi
}

run_awg() {
    local action="$1"
    local awg
    awg="$(command -v awg-quick 2>/dev/null || true)"
    [[ -n "$awg" ]] || { notify 'awg-quick не найден'; return 1; }
    [[ -f "$AWG_CONFIG" ]] || { notify "Конфиг не найден: $AWG_CONFIG"; return 1; }

    if command -v pkexec >/dev/null 2>&1; then
        if pkexec "$awg" "$action" "$AWG_CONFIG"; then
            notify "AWG $AWG_IFACE: $action выполнено"
        else
            notify "AWG $AWG_IFACE: действие отменено или завершилось ошибкой"
            return 1
        fi
    else
        local term=""
        for candidate in ghostty kitty foot; do
            if command -v "$candidate" >/dev/null 2>&1; then term="$candidate"; break; fi
        done
        [[ -n "$term" ]] || { notify 'Нужен pkexec или терминал для запроса sudo'; return 1; }
        local command_line
        printf -v command_line 'sudo %q %q %q; rc=$?; echo; read -r -p "Нажмите Enter..."; exit $rc' "$awg" "$action" "$AWG_CONFIG"
        case "$term" in
            ghostty) ghostty --title 'VPN authorization' -e bash -lc "$command_line" ;;
            kitty) kitty --title 'VPN authorization' bash -lc "$command_line" ;;
            foot) foot --title='VPN authorization' bash -lc "$command_line" ;;
        esac
    fi
    refresh
}

show_status() {
    ip -brief link show 2>/dev/null | grep -Ei '(^|[[:space:]])(awg|wg|tun|tap|amnezia)' || true
    nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | grep -E '^(vpn|wireguard):' || true
}

case "$mode" in
    amnezia)
        open_amnezia
        exit
        ;;
    up|down)
        run_awg "$mode"
        exit
        ;;
    menu) ;;
    *) echo "usage: $0 {menu|amnezia|up|down}" >&2; exit 2 ;;
esac

command -v rofi >/dev/null 2>&1 || { notify 'rofi не найден'; exit 1; }

if ip link show "$AWG_IFACE" >/dev/null 2>&1; then
    awg_item="󰌿  Отключить AWG: $AWG_IFACE"
else
    awg_item="󰌾  Подключить AWG: $AWG_IFACE"
fi

choice="$({
    printf '%s\n' "$awg_item"
    printf '%s\n' '󰖂  Открыть AmneziaVPN'
    printf '%s\n' '󰋼  Показать активные VPN-интерфейсы'
} | rofi -dmenu -i -p 'VPN')" || exit 0

case "$choice" in
    *'Подключить AWG'*) run_awg up ;;
    *'Отключить AWG'*) run_awg down ;;
    *'Открыть AmneziaVPN'*) open_amnezia ;;
    *'Показать активные'*)
        status="$(show_status)"
        [[ -n "$status" ]] || status='Активных VPN-интерфейсов нет'
        printf '%s\n' "$status" | rofi -dmenu -i -p 'VPN status' >/dev/null || true
        ;;
esac
