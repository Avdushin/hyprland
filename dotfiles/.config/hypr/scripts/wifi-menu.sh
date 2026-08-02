#!/usr/bin/env bash
set -euo pipefail

if [[ -x $HOME/bin/wifimenu ]]; then
  exec "$HOME/bin/wifimenu"
fi

if command -v nmtui >/dev/null 2>&1 && command -v ghostty >/dev/null 2>&1; then
  exec ghostty --title "Wi-Fi" -e nmtui-connect
fi

notify-send -u critical "Wi-Fi" "Не найден ни ~/bin/wifimenu, ни nmtui" 2>/dev/null || true

