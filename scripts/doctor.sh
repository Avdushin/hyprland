#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

failures=0
warnings=0

ok()   { printf '  [OK]   %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; failures=$((failures + 1)); }
soft() { printf '  [WARN] %s\n' "$*"; warnings=$((warnings + 1)); }

note 'Required commands'
for cmd in Hyprland hyprctl waybar alacritty rofi wofi thunar mako hyprlock hypridle swaybg grim slurp wl-copy cliphist jq python3 nmcli wpctl; do
  command -v "$cmd" >/dev/null 2>&1 && ok "$cmd" || bad "$cmd not found"
done

note 'Configuration files'
for file in \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/hypr/generated-theme.lua" \
  "$HOME/.config/waybar/config.jsonc" \
  "$HOME/.config/alacritty/alacritty.toml" \
  "$HOME/.config/rofi/fog-and-ember.rasi" \
  "$HOME/.config/wofi/style.css" \
  "$HOME/.config/Thunar/uca.xml"; do
  [[ -s $file ]] && ok "${file#$HOME/}" || bad "missing: $file"
done

note 'Syntax checks'
while IFS= read -r -d '' file; do
  bash -n "$file" && ok "bash: ${file#$HOME/}" || bad "bash: $file"
done < <(
  find \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/waybar/scripts" \
    -type f -name '*.sh' -print0 2>/dev/null
)

python3 -m json.tool "$HOME/.config/waybar/config.jsonc" >/dev/null 2>&1 \
  && ok 'Waybar JSON' || bad 'Waybar JSON'

if command -v python3 >/dev/null 2>&1; then
  if python3 - "$HOME/.config/alacritty/alacritty.toml" <<'PY_TOML'
import sys
import tomllib

with open(sys.argv[1], "rb") as fh:
    tomllib.load(fh)
PY_TOML
  then
    ok 'Alacritty TOML'
  else
    bad 'Alacritty TOML'
  fi

  if python3 - "$HOME/.config/Thunar/uca.xml" <<'PY_XML'
import sys
import xml.etree.ElementTree as ET

ET.parse(sys.argv[1])
PY_XML
  then
    ok 'Thunar XML'
  else
    bad 'Thunar XML'
  fi

  if python3 -m py_compile "$HOME/.config/waybar/scripts/language.py" >/dev/null 2>&1; then
    ok 'Waybar Python'
  else
    bad 'Waybar Python'
  fi
fi

note 'Hyprland version'
if command -v Hyprland >/dev/null 2>&1; then
  version_output=$(Hyprland --version 2>&1 | head -n 5 || true)
  printf '%s\n' "$version_output" | sed 's/^/  /'
  version=$(printf '%s\n' "$version_output" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
  if [[ -n $version ]]; then
    minimum=0.56.0
    first=$(printf '%s\n%s\n' "$minimum" "$version" | sort -V | head -n 1)
    [[ $first == "$minimum" ]] && ok "Hyprland $version supports this Lua config" \
      || bad "Hyprland $version is older than required $minimum"
  else
    soft 'Could not parse Hyprland version'
  fi
fi

note 'Theme naming'
if grep -RInI -E 'Obsidian Aqua|obsidian-aqua|hypr-obsidian-aqua|aquaOut|aquaFast' \
  "$HOME/.config/hypr" "$HOME/.config/rofi" "$HOME/.config/waybar" 2>/dev/null; then
  bad 'stale theme identifiers found'
else
  ok 'Fog & Ember naming is consistent'
fi

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  note 'Live Hyprland session'
  hyprctl monitors >/dev/null 2>&1 && ok 'hyprctl monitors' || soft 'hyprctl cannot query monitors'
  systemctl --user is-active waybar-fog-and-ember.service >/dev/null 2>&1 \
    && ok 'Waybar user service is active' || soft 'Waybar user service is not active'
fi

printf '\nResult: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
((failures == 0))
