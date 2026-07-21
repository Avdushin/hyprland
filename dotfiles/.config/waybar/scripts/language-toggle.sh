#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v hyprctl >/dev/null 2>&1; then
    command -v notify-send >/dev/null 2>&1 && notify-send 'Keyboard layout' 'hyprctl was not found'
    exit 1
fi

# Switch every keyboard together, so an external keyboard cannot drift away
# from the main one. The long-running language.py module receives the event.
hyprctl switchxkblayout all next >/dev/null
