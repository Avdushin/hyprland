#!/usr/bin/env bash
set -euo pipefail

if pgrep -x waybar >/dev/null 2>&1; then
  pkill -USR1 -x waybar
else
  exec "$HOME/.config/hypr/scripts/launch-waybar.sh"
fi

