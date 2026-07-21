#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

stamp=$(date +%Y-%m-%d_%H-%M-%S)
backup_root=${1:-"${XDG_STATE_HOME:-$HOME/.local/state}/fog-and-ember/backups/$stamp"}
manifest="$repo_root/managed-paths.txt"
mkdir -p "$backup_root/home"

while IFS= read -r relative; do
  [[ -n $relative && ${relative:0:1} != '#' ]] || continue
  source_path="$HOME/$relative"
  [[ -e $source_path || -L $source_path ]] || continue
  mkdir -p "$backup_root/home/$(dirname -- "$relative")"
  cp -a -- "$source_path" "$backup_root/home/$relative"
done < "$manifest"

printf '%s\n' "$backup_root"
