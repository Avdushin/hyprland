#!/usr/bin/env bash
set -Eeuo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
waybar_dir="$config_home/waybar"

runtime_dir="${XDG_RUNTIME_DIR:-/tmp/hypr-$UID}"
runtime_config="$runtime_dir/fog-and-ember-waybar.json"
runtime_lock="$runtime_dir/fog-and-ember-waybar.lock"

template="$waybar_dir/config.template.json"
renderer="$waybar_dir/scripts/render-config.py"
service="waybar-fog-and-ember.service"

mkdir -p "$runtime_dir"

exec 9>"$runtime_lock"
flock -x 9

[[ -f "$template" ]] || {
    echo "Waybar template not found: $template" >&2
    exit 1
}

[[ -x "$renderer" ]] || {
    echo "Waybar renderer not found: $renderer" >&2
    exit 1
}

tmp="$(mktemp "${runtime_config}.XXXXXX")"
trap 'rm -f -- "$tmp"' EXIT

python3 "$renderer" "$template" >"$tmp"

if command -v jq >/dev/null 2>&1; then
    jq -e . "$tmp" >/dev/null
else
    python3 -m json.tool "$tmp" >/dev/null
fi

mv -f -- "$tmp" "$runtime_config"
trap - EXIT

dbus-update-activation-environment \
    --systemd \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    HYPRLAND_INSTANCE_SIGNATURE \
    2>/dev/null || true

systemctl --user import-environment \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    HYPRLAND_INSTANCE_SIGNATURE \
    2>/dev/null || true

systemctl --user daemon-reload >/dev/null 2>&1 || true

if systemctl --user restart "$service" >/dev/null 2>&1; then
    exit 0
fi

pkill -x waybar >/dev/null 2>&1 || true

nohup waybar \
    -c "$runtime_config" \
    -s "$waybar_dir/style.css" \
    >/dev/null 2>&1 &
