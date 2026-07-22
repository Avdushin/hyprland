#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-click}"
runtime="${XDG_RUNTIME_DIR:-/tmp}"
state="$runtime/waybar-trash-last-click-${UID}"
lock="$runtime/waybar-trash-click-${UID}.lock"

refresh() {
    pkill -RTMIN+10 -x waybar 2>/dev/null || true
}

open_trash() {
    if command -v thunar >/dev/null 2>&1; then
        thunar 'trash:///' >/dev/null 2>&1 &
    elif command -v gio >/dev/null 2>&1; then
        gio open 'trash:///' >/dev/null 2>&1 &
    else
        xdg-open 'trash:///' >/dev/null 2>&1 &
    fi
}

empty_trash() {
    if ! command -v gio >/dev/null 2>&1; then
        command -v notify-send >/dev/null 2>&1 && notify-send 'Корзина' 'Команда gio не найдена'
        return 1
    fi
    gio trash --empty
    command -v notify-send >/dev/null 2>&1 && notify-send 'Корзина' 'Корзина очищена'
    refresh
}

case "$mode" in
    open)
        open_trash
        ;;
    empty)
        empty_trash
        ;;
    click)
        # Waybar has no dedicated double-click action. Detect two left clicks
        # within 700 ms while serializing concurrent click handlers.
        exec 9>"$lock"
        flock 9
        now="$(date +%s%3N)"
        last=0
        [[ -s "$state" ]] && read -r last < "$state" || true
        if [[ "$last" =~ ^[0-9]+$ ]] && (( now - last >= 0 && now - last <= 700 )); then
            rm -f -- "$state"
            empty_trash
        else
            printf '%s\n' "$now" > "$state"
        fi
        ;;
    *)
        echo "usage: $0 {click|open|empty}" >&2
        exit 2
        ;;
esac
