#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
    pwd
)"
cd "$repo_root"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

fail() {
    printf 'Repository check failed: %s\n' "$*" >&2
    exit 1
}

echo 'Checking Bash syntax...'

while IFS= read -r -d '' file; do
    bash -n "$file"
done < <(
    find . \
        -type f \
        -name '*.sh' \
        -not -path './.git/*' \
        -print0
)

echo 'Checking required files...'

required_files=(
    dotfiles/.config/hypr/palette.conf
    dotfiles/.config/hypr/scripts/launch-waybar.sh
    dotfiles/.config/hypr/scripts/sync-theme.sh
    dotfiles/.config/hypr/scripts/headset-battery.sh
    dotfiles/.config/hypr/user-settings.sh.example
    dotfiles/.config/waybar/config.template.json
    dotfiles/.config/waybar/style.css
    dotfiles/.config/waybar/scripts/render-config.py
    dotfiles/.config/waybar/scripts/language.py
    dotfiles/.config/waybar/scripts/trash-status.py
    dotfiles/.config/waybar/scripts/trash-action.sh
    dotfiles/.config/waybar/scripts/vpn-status.py
    dotfiles/.config/waybar/scripts/vpn-menu.sh
    dotfiles/.config/systemd/user/waybar-fog-and-ember.service
    dotfiles/.config/alacritty/alacritty.toml
    dotfiles/.config/rofi/fog-and-ember.rasi
    dotfiles/.config/Thunar/uca.xml
)

for file in "${required_files[@]}"; do
    [[ -s "$file" ]] || fail "missing or empty file: $file"
done

legacy_waybar="dotfiles/.config/waybar/config.jsonc"

[[ ! -e "$legacy_waybar" ]] || {
    fail "legacy Waybar config remains: $legacy_waybar"
}

echo 'Checking executable files...'

executable_files=(
    install.sh
    scripts/check-repo.sh
    scripts/doctor.sh
    dotfiles/.config/hypr/scripts/launch-waybar.sh
    dotfiles/.config/hypr/scripts/sync-theme.sh
    dotfiles/.config/hypr/scripts/headset-battery.sh
    dotfiles/.config/waybar/scripts/render-config.py
    dotfiles/.config/waybar/scripts/trash-status.py
    dotfiles/.config/waybar/scripts/trash-action.sh
    dotfiles/.config/waybar/scripts/vpn-status.py
    dotfiles/.config/waybar/scripts/vpn-menu.sh
)

for file in "${executable_files[@]}"; do
    [[ -x "$file" ]] || fail "file is not executable: $file"
done

echo 'Checking structured files...'

python3 -m json.tool \
    dotfiles/.config/waybar/config.template.json \
    >/dev/null

python3 - <<'PY'
import tomllib
import xml.etree.ElementTree as ET

with open(
    "dotfiles/.config/alacritty/alacritty.toml",
    "rb",
) as stream:
    tomllib.load(stream)

ET.parse("dotfiles/.config/Thunar/uca.xml")
PY

echo 'Checking Python syntax...'

mapfile -d '' python_files < <(
    find dotfiles/.config/waybar/scripts \
        -type f \
        -name '*.py' \
        -print0
)

PYTHONPYCACHEPREFIX="$tmp_dir/pycache" \
    python3 -m py_compile "${python_files[@]}"

echo 'Checking adaptive Waybar rendering...'

python3 - <<'PY'
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

renderer = Path(
    "dotfiles/.config/waybar/scripts/render-config.py"
)
template = Path(
    "dotfiles/.config/waybar/config.template.json"
)


def monitor(
    name: str,
    x: int,
    width: int,
    height: int,
    transform: int = 0,
) -> dict[str, object]:
    return {
        "name": name,
        "x": x,
        "y": 0,
        "width": width,
        "height": height,
        "transform": transform,
        "disabled": False,
    }


fixtures = {
    1: [
        monitor("eDP-1", 0, 1920, 1080),
    ],
    2: [
        monitor("HDMI-A-1", 0, 1920, 1080),
        monitor("DP-1", 1920, 2560, 1440),
    ],
    3: [
        monitor("DP-1", 0, 1920, 1080),
        monitor("DP-2", 1920, 2560, 1440),
        monitor("HDMI-A-1", 4480, 1920, 1080, 1),
    ],
    4: [
        monitor("DP-0", -1920, 1920, 1080),
        monitor("DP-1", 0, 1920, 1080),
        monitor("DP-2", 1920, 2560, 1440),
        monitor("HDMI-A-1", 4480, 1920, 1080, 1),
    ],
}

rendered_fixtures: dict[int, list[dict[str, object]]] = {}

for count, monitors in fixtures.items():
    environment = os.environ.copy()
    environment["WAYBAR_MONITORS_JSON"] = json.dumps(monitors)

    raw = subprocess.check_output(
        [
            sys.executable,
            str(renderer),
            str(template),
        ],
        text=True,
        env=environment,
    )

    bars = json.loads(raw)

    assert isinstance(bars, list)
    assert len(bars) == count, (count, len(bars))

    outputs = [bar.get("output") for bar in bars]

    assert None not in outputs
    assert len(outputs) == len(set(outputs))

    rendered_fixtures[count] = bars

three = rendered_fixtures[3]

summary = {
    str(bar["output"]): sorted(
        bar["hyprland/workspaces"]
        ["persistent-workspaces"]
        .keys(),
        key=int,
    )
    for bar in three
}

expected = {
    "DP-1": ["0"],
    "DP-2": ["1", "2", "3", "4", "5", "6", "7"],
    "HDMI-A-1": ["8", "9"],
}

assert summary == expected, summary

one = rendered_fixtures[1][0]

one_workspaces = sorted(
    one["hyprland/workspaces"]
    ["persistent-workspaces"]
    .keys(),
    key=int,
)

assert one_workspaces == [
    str(number)
    for number in range(1, 10)
]

print("Adaptive Waybar fixtures: OK")
PY

echo 'Checking Waybar launch integration...'

service="dotfiles/.config/systemd/user/waybar-fog-and-ember.service"
launcher="dotfiles/.config/hypr/scripts/launch-waybar.sh"

grep -qF \
    '%t/fog-and-ember-waybar.json' \
    "$service" ||
    fail "systemd service does not use runtime Waybar config"

if grep -qF 'config.jsonc' "$service"; then
    fail "systemd service still uses config.jsonc"
fi

grep -qF \
    'render-config.py' \
    "$launcher" ||
    fail "launch-waybar.sh does not invoke adaptive renderer"

grep -qF \
    'fog-and-ember-waybar.json' \
    "$launcher" ||
    fail "launch-waybar.sh does not create runtime config"

echo 'Checking palette integration...'

palette="dotfiles/.config/hypr/palette.conf"
sync_theme="dotfiles/.config/hypr/scripts/sync-theme.sh"

for key in \
    CPU \
    MEMORY \
    BLUETOOTH \
    VPN_IDLE \
    AUDIO \
    HEADSET \
    NETWORK
do
    grep -qE "^${key}=[0-9A-Fa-f]{6}$" "$palette" ||
        fail "missing palette value: $key"
done

for color in \
    cpu \
    memory \
    bluetooth \
    vpn_idle \
    audio \
    headset \
    network
do
    grep -qF "@define-color $color " "$sync_theme" ||
        fail "sync-theme.sh does not generate: $color"
done

echo 'Checking package dependencies...'

for package in btop calcurse iproute2; do
    grep -qxF "$package" packages/arch.txt ||
        fail "missing Arch package: $package"
done

for package in btop calcurse iproute; do
    grep -qxF "$package" packages/fedora.txt ||
        fail "missing Fedora package: $package"
done

echo 'Checking theme naming...'

if git grep -nI \
    -E 'Obsidian Aqua|obsidian-aqua|hypr-obsidian-aqua|aquaOut|aquaFast' \
    -- \
    ':!.github/workflows/check.yml' \
    ':!scripts/doctor.sh' \
    ':!scripts/check-repo.sh'
then
    fail 'stale theme identifiers found'
fi

echo 'Checking absolute home paths...'

if git grep -nI -E '/home/[A-Za-z0-9._-]+/'; then
    fail 'absolute home path found'
fi

echo 'Checking vendor-specific packages and settings...'

if grep -RInI \
    -E 'amd-ucode|nvidia|amdgpu|vulkan-radeon|linux-firmware' \
    --exclude=check-repo.sh \
    packages \
    install.sh \
    scripts \
    dotfiles
then
    fail 'vendor driver package or setting found'
fi

echo 'Checking whitespace...'

git diff --check
git diff --cached --check

printf 'Repository checks: OK\n'
