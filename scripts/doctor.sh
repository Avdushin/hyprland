#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

failures=0
warnings=0

ok() {
    printf '  [OK]   %s\n' "$*"
}

bad() {
    printf '  [FAIL] %s\n' "$*"
    failures=$((failures + 1))
}

soft() {
    printf '  [WARN] %s\n' "$*"
    warnings=$((warnings + 1))
}

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
hypr_dir="$config_home/hypr"
waybar_dir="$config_home/waybar"

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
runtime_waybar="$runtime_dir/fog-and-ember-waybar.json"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

note 'Required commands'

required_commands=(
    Hyprland
    hyprctl
    waybar
    ghostty
    rofi
    wofi
    thunar
    mako
    hyprlock
    hypridle
    swaybg
    grim
    slurp
    wl-copy
    cliphist
    jq
    python3
    nmcli
    wpctl
    ip
    gio
    flock
    playerctl
    bluetoothctl
    git
    ssh
    gh
    delta
    diffnav
    tuicr
    btop
    calcurse
)

for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd"
    else
        bad "$cmd not found"
    fi
done

note 'Optional desktop commands'

optional_commands=(
    pavucontrol
    nm-connection-editor
    blueman-manager
    notify-send
)

for cmd in "${optional_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd"
    else
        soft "$cmd not found"
    fi
done

note 'Configuration files'

required_files=(
    "$HOME/.gitconfig"
    "$hypr_dir/hyprland.lua"
    "$hypr_dir/palette.conf"
    "$hypr_dir/generated-theme.lua"
    "$hypr_dir/scripts/session-start.sh"
    "$hypr_dir/scripts/launch-waybar.sh"
    "$hypr_dir/scripts/wifi-menu.sh"
    "$waybar_dir/config.template.json"
    "$waybar_dir/style.css"
    "$waybar_dir/scripts/render-config.py"
    "$waybar_dir/scripts/language.py"
    "$waybar_dir/scripts/trash-status.py"
    "$waybar_dir/scripts/vpn-status.py"
    "$waybar_dir/scripts/vpn-menu.sh"
    "$waybar_dir/scripts/wifi-menu.sh"
    "$config_home/systemd/user/waybar-fog-and-ember.service"
    "$config_home/ghostty/config.ghostty"
    "$config_home/ghostty/themes/fog-and-ember"
    "$data_home/xfce4/helpers/custom-TerminalEmulator.desktop"
    "$config_home/rofi/fog-and-ember.rasi"
    "$config_home/wofi/style.css"
    "$config_home/Thunar/uca.xml"
)

for file in "${required_files[@]}"; do
    if [[ -s "$file" ]]; then
        ok "${file#$HOME/}"
    else
        bad "missing: $file"
    fi
done

note 'Git tooling'

if [[ "$(git config --global --get init.defaultBranch 2>/dev/null || true)" == main ]]; then
    ok 'Git default branch: main'
else
    bad 'Git default branch is not main'
fi

if [[ "$(git config --global --get core.pager 2>/dev/null || true)" == delta ]]; then
    ok 'Git core pager: delta'
else
    bad 'Git core pager is not delta'
fi

if [[ "$(git config --global --get pager.diff 2>/dev/null || true)" == diffnav ]]; then
    ok 'Git diff pager: diffnav'
else
    bad 'Git diff pager is not diffnav'
fi

if [[ -n "$(git config --global --get user.name 2>/dev/null || true)" &&
      -n "$(git config --global --get user.email 2>/dev/null || true)" ]]; then
    ok 'Personal Git identity is configured'
else
    soft 'Git user.name/user.email are not configured in ~/.gitconfig.local'
fi

legacy_waybar="$waybar_dir/config.jsonc"

if [[ -e "$legacy_waybar" ]]; then
    soft "legacy file remains: ${legacy_waybar#$HOME/}"
else
    ok 'legacy Waybar config.jsonc is absent'
fi

note 'Shell syntax'

while IFS= read -r -d '' file; do
    if bash -n "$file"; then
        ok "bash: ${file#$HOME/}"
    else
        bad "bash: $file"
    fi
done < <(
    find \
        "$hypr_dir/scripts" \
        "$waybar_dir/scripts" \
        -type f \
        -name '*.sh' \
        -print0 \
        2>/dev/null
)

note 'Waybar template'

if python3 -m json.tool \
    "$waybar_dir/config.template.json" \
    >/dev/null 2>&1; then
    ok 'Waybar template JSON'
else
    bad 'Waybar template JSON'
fi

fixture='[
  {
    "name": "eDP-1",
    "x": 0,
    "y": 0,
    "width": 1920,
    "height": 1080,
    "disabled": false
  }
]'

rendered="$tmp_dir/waybar-rendered.json"

if WAYBAR_MONITORS_JSON="$fixture" \
    python3 \
        "$waybar_dir/scripts/render-config.py" \
        "$waybar_dir/config.template.json" \
        >"$rendered" &&
   python3 -m json.tool "$rendered" >/dev/null 2>&1; then

    if python3 - "$rendered" <<'PY_RENDER'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    bars = json.load(stream)

assert isinstance(bars, list)
assert len(bars) == 1
assert bars[0].get("output") == "eDP-1"

workspaces = (
    bars[0]
    ["hyprland/workspaces"]
    ["persistent-workspaces"]
)

assert sorted(workspaces, key=int) == [
    str(number)
    for number in range(1, 10)
]
PY_RENDER
    then
        ok 'Waybar one-monitor rendering'
    else
        bad 'Waybar rendered structure'
    fi
else
    bad 'Waybar adaptive renderer'
fi

note 'Python syntax'

python_files=(
    "$waybar_dir/scripts/render-config.py"
    "$waybar_dir/scripts/language.py"
    "$waybar_dir/scripts/trash-status.py"
    "$waybar_dir/scripts/vpn-status.py"
    "$waybar_dir/scripts/vpn-menu.sh"
    "$waybar_dir/scripts/wifi-menu.sh"
)

python_ok=true

for file in "${python_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        bad "missing Python file: $file"
        python_ok=false
        continue
    fi

    if PYTHONPYCACHEPREFIX="$tmp_dir/pycache" \
        python3 -m py_compile "$file" >/dev/null 2>&1; then
        ok "python: ${file#$HOME/}"
    else
        bad "python: $file"
        python_ok=false
    fi
done

note 'Application configuration syntax'

if ghostty +show-config \
    --config-file="$config_home/ghostty/config.ghostty" \
    >/dev/null 2>&1; then
    ok 'Ghostty configuration'
else
    bad 'Ghostty configuration'
fi

if python3 - "$config_home/Thunar/uca.xml" <<'PY_XML'
import sys
import xml.etree.ElementTree as ET

ET.parse(sys.argv[1])
PY_XML
then
    ok 'Thunar XML'
else
    bad 'Thunar XML'
fi

if rofi \
    -no-config \
    -theme "$config_home/rofi/fog-and-ember.rasi" \
    -dump-theme \
    >/dev/null 2>&1; then
    ok 'Rofi theme'
else
    bad 'Rofi theme'
fi

note 'Hyprland version'

if command -v Hyprland >/dev/null 2>&1; then
    version_output="$(
        Hyprland --version 2>&1 |
            head -n 5 ||
            true
    )"

    printf '%s\n' "$version_output" |
        sed 's/^/  /'

    version="$(
        printf '%s\n' "$version_output" |
            grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' |
            head -n 1 ||
            true
    )"

    if [[ -n "$version" ]]; then
        minimum=0.56.0

        first="$(
            printf '%s\n%s\n' "$minimum" "$version" |
                sort -V |
                head -n 1
        )"

        if [[ "$first" == "$minimum" ]]; then
            ok "Hyprland $version supports this Lua config"
        else
            bad "Hyprland $version is older than required $minimum"
        fi
    else
        soft 'Could not parse Hyprland version'
    fi
fi

note 'Theme naming'

if grep -RInI \
    -E 'Obsidian Aqua|obsidian-aqua|hypr-obsidian-aqua|aquaOut|aquaFast' \
    "$hypr_dir" \
    "$config_home/rofi" \
    "$waybar_dir" \
    2>/dev/null; then
    bad 'stale theme identifiers found'
else
    ok 'Fog & Ember naming is consistent'
fi

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    note 'Live Hyprland session'

    if hyprctl monitors >/dev/null 2>&1; then
        ok 'hyprctl monitors'
    else
        soft 'hyprctl cannot query monitors'
    fi

    if [[ -s "$runtime_waybar" ]] &&
       python3 -m json.tool "$runtime_waybar" >/dev/null 2>&1; then
        ok "runtime Waybar config: ${runtime_waybar#$HOME/}"
    else
        soft "runtime Waybar config is unavailable: $runtime_waybar"
    fi

    if systemctl --user \
        is-active \
        waybar-fog-and-ember.service \
        >/dev/null 2>&1; then
        ok 'Waybar user service is active'
    else
        soft 'Waybar user service is not active'
    fi
fi

printf '\nResult: %d failure(s), %d warning(s)\n' \
    "$failures" \
    "$warnings"

((failures == 0))
