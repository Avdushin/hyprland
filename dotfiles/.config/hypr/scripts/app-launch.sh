#!/usr/bin/env bash
set -euo pipefail

app=${1:-}

run_first() {
  local candidate
  for candidate in "$@"; do
    if [[ $candidate == */* && -x $candidate ]]; then
      exec "$candidate"
    elif command -v "$candidate" >/dev/null 2>&1; then
      exec "$candidate"
    fi
  done
  return 1
}

resolve_binary() {
  local candidate=$1
  if [[ $candidate == */* && -x $candidate ]]; then
    printf '%s\n' "$candidate"
  else
    command -v "$candidate" 2>/dev/null
  fi
}

launch_zen() {
  local runtime_dir log candidate binary pid status
  runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-fog-and-ember"
  log="$runtime_dir/zen-browser.log"
  mkdir -p "$runtime_dir"

  # zen-browser worked from the old i3 config. The most common difference in
  # an UWSM session is that fish's ~/.local/bin PATH addition is not present.
  # Try package, local and manual-install paths explicitly.
  for candidate in \
    zen-browser zen \
    "$HOME/.local/bin/zen-browser" "$HOME/.local/bin/zen" \
    /opt/zen-browser/zen /opt/zen/zen /usr/local/bin/zen-browser; do
    binary=$(resolve_binary "$candidate" || true)
    [[ -n $binary ]] || continue

    printf '\n[%s] native Wayland: %s\n' "$(date --iso-8601=seconds)" "$binary" >>"$log"
    env MOZ_ENABLE_WAYLAND=1 "$binary" >>"$log" 2>&1 &
    pid=$!
    sleep 0.8

    if kill -0 "$pid" 2>/dev/null; then
      disown "$pid" 2>/dev/null || true
      return 0
    fi

    if wait "$pid"; then
      # Firefox-family launchers may hand the request to an existing process
      # and immediately exit successfully.
      return 0
    else
      status=$?
    fi

    printf '[%s] Wayland start failed (%s); trying XWayland fallback\n' \
      "$(date --iso-8601=seconds)" "$status" >>"$log"
    env MOZ_ENABLE_WAYLAND=0 "$binary" >>"$log" 2>&1 &
    pid=$!
    sleep 0.8
    if kill -0 "$pid" 2>/dev/null; then
      disown "$pid" 2>/dev/null || true
      return 0
    fi
    if wait "$pid"; then
      return 0
    fi
  done

  if command -v flatpak >/dev/null 2>&1 && \
      flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    printf '\n[%s] Flatpak Zen\n' "$(date --iso-8601=seconds)" >>"$log"
    flatpak run app.zen_browser.zen >>"$log" 2>&1 &
    return 0
  fi

  # Last fallback: use the desktop entry, whose Exec line knows the exact
  # installation path used by the local Zen package.
  if command -v gtk-launch >/dev/null 2>&1; then
    for candidate in zen-browser app.zen_browser.zen; do
      if gtk-launch "$candidate" >>"$log" 2>&1; then
        return 0
      fi
    done
  fi

  notify-send -u critical "Zen Browser" \
    "Запуск не удался. Диагностика записана в: $log" 2>/dev/null || true
  return 1
}

case "$app" in
  terminal) run_first ghostty || true ;;
  sublime) run_first /opt/sublime-text/sublime_text /opt/sublime_text/sublime_text subl || true ;;
  codium) run_first codium || true ;;
  telegram) run_first Telegram telegram-desktop || true ;;
  discord) run_first discord vesktop || true ;;
  thunar) run_first thunar || true ;;
  obsidian) run_first obsidian || true ;;
  browser) launch_zen && exit 0 ;;
esac

notify-send -u critical "Hyprland" "Не найдена команда для приложения: $app" 2>/dev/null || true
exit 127
