#!/usr/bin/env bash
set -Eeuo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
service="waybar-fog-and-ember.service"

systemctl --user daemon-reload >/dev/null 2>&1 || true
if systemctl --user restart "$service" >/dev/null 2>&1; then
  exit 0
fi

pkill -x waybar >/dev/null 2>&1 || true
nohup waybar \
  -c "$config_home/waybar/config.jsonc" \
  -s "$config_home/waybar/style.css" \
  >/dev/null 2>&1 &
