#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/cliphist-preview"
theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/fog-and-ember.rasi"
mkdir -p "$cache_dir"
find "$cache_dir" -type f -mtime +7 -delete 2>/dev/null || true

build_entries() {
  local line id preview image mime label
  while IFS= read -r line; do
    [[ -n $line ]] || continue
    id=${line%%[[:space:]]*}
    preview=${line#*$'\t'}

    if [[ $id =~ ^[0-9]+$ && $preview == *"binary data"* ]]; then
      image="$cache_dir/$id"
      if [[ ! -s $image ]]; then
        cliphist decode <<<"$line" >"$image" 2>/dev/null || rm -f "$image"
      fi
      mime=$(file --brief --mime-type "$image" 2>/dev/null || true)
      if [[ $mime == image/* ]]; then
        label="$id"$'\t'"󰋩  Clipboard image #$id"
        printf '%s\0icon\x1f%s\n' "$label" "$image"
        continue
      fi
    fi

    printf '%s\n' "$line"
  done < <(cliphist list)
}

set +e
selection=$(build_entries | rofi -dmenu -i -show-icons -p "Clipboard" -theme "$theme")
status=$?
set -e
[[ $status -eq 0 && -n $selection ]] || exit 0

id=${selection%%[[:space:]]*}
cached="$cache_dir/$id"
if [[ -s $cached ]]; then
  mime=$(file --brief --mime-type "$cached" 2>/dev/null || true)
  if [[ $mime == image/* ]]; then
    wl-copy --type "$mime" <"$cached"
    exit 0
  fi
fi

cliphist decode <<<"$selection" | wl-copy
