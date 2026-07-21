#!/usr/bin/env bash
set -Eeuo pipefail

mode=${1:-area}
directory="${XDG_PICTURES_DIR:-$HOME/Images}/Screenshots"
mkdir -p "$directory"

reset_submap() {
  hyprctl dispatch submap reset >/dev/null 2>&1 || true
}

capture() {
  local geometry=${1:-}
  local file="$directory/$(date '+%Y-%m-%d_%H-%M-%S').png"
  if [[ -n $geometry ]]; then
    grim -g "$geometry" "$file"
  else
    grim "$file"
  fi
  wl-copy --type image/png <"$file"
  notify-send 'Screenshot' "Saved and copied: ${file##*/}" 2>/dev/null || true
}

capture_area_or_window() {
  local rectangles geometry
  rectangles=$(hyprctl clients -j | jq -r '
    .[]
    | select((.mapped // true) == true)
    | select(.hidden == false)
    | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title | gsub("[\\r\\n]"; " "))"
  ' 2>/dev/null || true)

  if [[ -n $rectangles ]]; then
    geometry=$(slurp -d <<<"$rectangles") || return 0
  else
    geometry=$(slurp -d) || return 0
  fi
  [[ -n $geometry ]] && capture "$geometry"
}

case "$mode" in
  all) reset_submap; capture ;;
  all-from-selector)
    pkill -x slurp 2>/dev/null || true
    reset_submap
    sleep 0.08
    capture
    ;;
  cancel)
    pkill -x slurp 2>/dev/null || true
    reset_submap
    ;;
  area)
    trap reset_submap EXIT
    capture_area_or_window
    ;;
  *) printf 'Unknown screenshot mode: %s\n' "$mode" >&2; exit 2 ;;
esac
