#!/usr/bin/env bash
set -u

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
scripts="$config_dir/scripts"
log_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-fog-and-ember"
mkdir -p "$log_dir"

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

"$scripts/sync-theme.sh" --no-reload || true
"$scripts/launch-waybar.sh" || true
"$scripts/wallpaper.sh" restore || true

if ! pgrep -x mako >/dev/null 2>&1; then
  mako >"$log_dir/mako.log" 2>&1 &
fi

if command -v hypridle >/dev/null 2>&1 && ! pgrep -x hypridle >/dev/null 2>&1; then
  hypridle >"$log_dir/hypridle.log" 2>&1 &
fi

if command -v nm-applet >/dev/null 2>&1 && ! pgrep -x nm-applet >/dev/null 2>&1; then
  nm-applet --indicator >"$log_dir/nm-applet.log" 2>&1 &
fi

if ! pgrep -f '[h]yprpolkitagent' >/dev/null 2>&1; then
  for agent in \
    "$(command -v hyprpolkitagent 2>/dev/null || true)" \
    /usr/lib/hyprpolkitagent/hyprpolkitagent \
    /usr/libexec/hyprpolkitagent; do
    [[ -n $agent && -x $agent ]] || continue
    "$agent" >"$log_dir/polkit.log" 2>&1 &
    break
  done
fi

if command -v cliphist >/dev/null 2>&1; then
  if ! pgrep -f '^wl-paste --type text --watch cliphist store$' >/dev/null 2>&1; then
    wl-paste --type text --watch cliphist store >"$log_dir/cliphist-text.log" 2>&1 &
  fi
  if ! pgrep -f '^wl-paste --type image --watch cliphist store$' >/dev/null 2>&1; then
    wl-paste --type image --watch cliphist store >"$log_dir/cliphist-image.log" 2>&1 &
  fi
fi
