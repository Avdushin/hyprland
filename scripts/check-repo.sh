#!/usr/bin/env bash
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find . -type f -name '*.sh' -not -path './.git/*' -print0)

python3 -m json.tool dotfiles/.config/waybar/config.jsonc >/dev/null
python3 - <<'PY'
import tomllib
import xml.etree.ElementTree as ET
with open('dotfiles/.config/alacritty/alacritty.toml', 'rb') as fh:
    tomllib.load(fh)
ET.parse('dotfiles/.config/Thunar/uca.xml')
PY
python3 -m py_compile dotfiles/.config/waybar/scripts/language.py

git diff --check
if git grep -nI -E 'Obsidian Aqua|obsidian-aqua|hypr-obsidian-aqua|aquaOut|aquaFast' -- \
  ':!.github/workflows/check.yml' ':!scripts/doctor.sh' ':!scripts/check-repo.sh'; then
  printf 'Stale theme identifiers found\n' >&2
  exit 1
fi
if git grep -nI -E '/home/[A-Za-z0-9._-]+/'; then
  printf 'Absolute home path found\n' >&2
  exit 1
fi
if grep -RInI -E 'amd-ucode|nvidia|amdgpu|vulkan-radeon|linux-firmware' \
  --exclude=check-repo.sh packages install.sh scripts dotfiles; then
  printf 'Vendor driver package or setting found\n' >&2
  exit 1
fi
printf 'Repository checks: OK\n'
