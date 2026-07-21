#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

backup=${1:-}
[[ -n $backup && -d $backup/home ]] || die "Usage: $0 BACKUP_DIRECTORY"

note "Restoring files from $backup"
rsync -a -- "$backup/home/" "$HOME/"
systemctl --user daemon-reload >/dev/null 2>&1 || true
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null 2>&1 || true
fi
note 'Restore completed'
