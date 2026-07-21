#!/usr/bin/env bash
set -Eeuo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/fog-and-ember"
current_file="$state_dir/wallpaper"
pid_file="$state_dir/swaybg.pid"
log_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-fog-and-ember"
wallpaper_dir="${WALLPAPER_DIR:-$HOME/.local/share/fog-and-ember/wallpapers}"
favorite_dir="${FAVORITE_WALLPAPERS_DIR:-$wallpaper_dir/favorite}"

mkdir -p "$state_dir" "$log_dir" "$favorite_dir"

list_images() {
  local root=$1 max_depth=$2
  find "$root" -maxdepth "$max_depth" -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -print0 2>/dev/null
}

first_favorite() {
  local -a files=()
  mapfile -d '' -t files < <(list_images "$favorite_dir" 1 | sort -zV)
  ((${#files[@]})) || return 1
  printf '%s\n' "${files[0]}"
}

next_favorite() {
  local -a files=()
  local current='' index
  mapfile -d '' -t files < <(list_images "$favorite_dir" 1 | sort -zV)
  ((${#files[@]})) || return 1
  [[ -f $current_file ]] && current=$(<"$current_file")
  for index in "${!files[@]}"; do
    if [[ ${files[$index]} == "$current" ]]; then
      printf '%s\n' "${files[$(((index + 1) % ${#files[@]}))]}"
      return
    fi
  done
  printf '%s\n' "${files[0]}"
}

pick_random() {
  list_images "$wallpaper_dir" 3 | shuf -z -n 1 | tr -d '\0'
}

action=${1:-restore}
case "$action" in
  favorite) image=$(next_favorite || true) ;;
  random) image=$(pick_random || true) ;;
  restore)
    image=''
    [[ -f $current_file ]] && image=$(<"$current_file")
    [[ -f ${image:-} ]] || image=$(first_favorite || true)
    [[ -f ${image:-} ]] || image=$(pick_random || true)
    ;;
  *) image=$action ;;
esac

if [[ -z ${image:-} || ! -f $image ]]; then
  notify-send -u critical 'Fog & Ember' 'No wallpaper image was found' 2>/dev/null || true
  exit 1
fi

old_pid=''
[[ -f $pid_file ]] && old_pid=$(<"$pid_file")

swaybg -m fill -i "$image" >"$log_dir/swaybg.log" 2>&1 &
new_pid=$!
printf '%s\n' "$new_pid" >"$pid_file"
printf '%s\n' "$image" >"$current_file"

sleep 0.15
if [[ $old_pid =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
  kill "$old_pid" 2>/dev/null || true
fi
