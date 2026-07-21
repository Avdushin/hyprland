#!/usr/bin/env bash
set -Eeuo pipefail

app=${1:-}

notify_missing() {
  command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Fog & Ember" "$1" || true
}

run_first() {
  local candidate
  for candidate in "$@"; do
    if command -v "$candidate" >/dev/null 2>&1; then
      nohup "$candidate" >/dev/null 2>&1 &
      return 0
    fi
  done
  return 1
}

case "$app" in
  terminal)
    run_first alacritty foot kitty || notify_missing "Terminal emulator not found"
    ;;
  files)
    run_first thunar nautilus dolphin || notify_missing "File manager not found"
    ;;
  browser)
    if [[ -n ${BROWSER:-} ]] && command -v "${BROWSER%% *}" >/dev/null 2>&1; then
      nohup bash -lc "$BROWSER" >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then
      nohup xdg-open 'https://start.duckduckgo.com/' >/dev/null 2>&1 &
    else
      notify_missing "No default web browser could be opened"
    fi
    ;;
  *)
    notify_missing "Unknown launcher target: $app"
    exit 2
    ;;
esac
