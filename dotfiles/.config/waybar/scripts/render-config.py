#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def load_monitors() -> list[dict[str, Any]]:
    injected = os.environ.get("WAYBAR_MONITORS_JSON")

    if injected:
        raw: Any = json.loads(injected)
    else:
        try:
            output = subprocess.check_output(
                ["hyprctl", "monitors", "-j"],
                text=True,
                stderr=subprocess.DEVNULL,
                timeout=5,
            )
            raw = json.loads(output)
        except Exception:
            return []

    if not isinstance(raw, list):
        return []

    monitors: list[dict[str, Any]] = []

    for monitor in raw:
        if not isinstance(monitor, dict):
            continue

        if bool(monitor.get("disabled", False)):
            continue

        width = int(monitor.get("width", 0) or 0)
        height = int(monitor.get("height", 0) or 0)
        name = str(monitor.get("name", ""))

        if not name or width <= 0 or height <= 0:
            continue

        monitors.append(monitor)

    return sorted(
        monitors,
        key=lambda monitor: (
            int(monitor.get("x", 0) or 0),
            int(monitor.get("y", 0) or 0),
            str(monitor.get("name", "")),
        ),
    )


def area(monitor: dict[str, Any]) -> int:
    return (
        int(monitor.get("width", 0) or 0)
        * int(monitor.get("height", 0) or 0)
    )


def prepare_bar(
    template: dict[str, Any],
    monitor: dict[str, Any] | None,
    workspaces: list[int],
    *,
    position: str,
    dynamic_workspaces: bool = False,
) -> dict[str, Any]:
    bar = copy.deepcopy(template)

    if monitor is None:
        bar.pop("output", None)
    else:
        bar["output"] = str(monitor["name"])

    bar["position"] = position

    workspace_module = bar.get("hyprland/workspaces")
    if isinstance(workspace_module, dict):
        if dynamic_workspaces:
            workspace_module["format"] = "{name}"
            workspace_module["format-icons"] = {"default": ""}
            workspace_module["persistent-workspaces"] = {}
        else:
            workspace_module["format"] = "{icon}"
            workspace_module["format-icons"] = {
                **{str(number): str(number) for number in workspaces},
                "default": "",
            }

            output = (
                str(monitor["name"])
                if monitor is not None
                else "*"
            )

            workspace_module["persistent-workspaces"] = {
                str(number): [output]
                for number in workspaces
            }

    return bar


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "usage: render-config.py CONFIG_TEMPLATE",
            file=sys.stderr,
        )
        return 2

    template_path = Path(sys.argv[1])
    data = json.loads(template_path.read_text(encoding="utf-8"))

    if not isinstance(data, list):
        raise SystemExit("Waybar template must contain a JSON array")

    profiles: dict[str, dict[str, Any]] = {}

    for bar in data:
        if not isinstance(bar, dict):
            continue

        output = str(bar.get("output", ""))
        if output:
            profiles[output] = bar

    required = {"@LEFT@", "@CENTER@", "@RIGHT@"}
    missing = required - profiles.keys()

    if missing:
        raise SystemExit(
            "Missing Waybar profiles: " + ", ".join(sorted(missing))
        )

    monitors = load_monitors()

    # Без доступного hyprctl остаётся безопасная полноценная панель.
    if not monitors:
        result = [
            prepare_bar(
                profiles["@CENTER@"],
                None,
                list(range(1, 10)),
                position="top",
            )
        ]
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return 0

    count = len(monitors)
    bars: list[tuple[int, dict[str, Any]]] = []

    if count == 1:
        monitor = monitors[0]

        bars.append(
            (
                int(monitor.get("x", 0) or 0),
                prepare_bar(
                    profiles["@CENTER@"],
                    monitor,
                    list(range(1, 10)),
                    position="top",
                ),
            )
        )

    elif count == 2:
        first, second = monitors

        # Главным считается дисплей с большей площадью.
        # При равенстве — расположенный правее.
        center = max(
            monitors,
            key=lambda monitor: (
                area(monitor),
                int(monitor.get("x", 0) or 0),
            ),
        )

        side = first if center is second else second

        if int(side.get("x", 0) or 0) < int(center.get("x", 0) or 0):
            side_profile = profiles["@LEFT@"]
            side_workspaces = [0]
            center_workspaces = list(range(1, 10))
        else:
            side_profile = profiles["@RIGHT@"]
            side_workspaces = [8, 9]
            center_workspaces = list(range(1, 8))

        bars.extend(
            [
                (
                    int(side.get("x", 0) or 0),
                    prepare_bar(
                        side_profile,
                        side,
                        side_workspaces,
                        position="top",
                    ),
                ),
                (
                    int(center.get("x", 0) or 0),
                    prepare_bar(
                        profiles["@CENTER@"],
                        center,
                        center_workspaces,
                        position="top",
                    ),
                ),
            ]
        )

    else:
        left = monitors[0]
        right = monitors[-1]
        interior = monitors[1:-1]

        center = max(
            interior,
            key=lambda monitor: (
                area(monitor),
                -abs(
                    int(monitor.get("x", 0) or 0)
                    - int(
                        (
                            int(left.get("x", 0) or 0)
                            + int(right.get("x", 0) or 0)
                        )
                        / 2
                    )
                ),
            ),
        )

        bars.extend(
            [
                (
                    int(left.get("x", 0) or 0),
                    prepare_bar(
                        profiles["@LEFT@"],
                        left,
                        [0],
                        position="top",
                    ),
                ),
                (
                    int(center.get("x", 0) or 0),
                    prepare_bar(
                        profiles["@CENTER@"],
                        center,
                        list(range(1, 8)),
                        position="top",
                    ),
                ),
                (
                    int(right.get("x", 0) or 0),
                    prepare_bar(
                        profiles["@RIGHT@"],
                        right,
                        [8, 9],
                        position="bottom",
                    ),
                ),
            ]
        )

        occupied = {
            str(left["name"]),
            str(center["name"]),
            str(right["name"]),
        }

        # Для четвёртого и последующих дисплеев создаётся
        # облегчённая динамическая панель без жёсткого набора workspace.
        for monitor in monitors:
            if str(monitor["name"]) in occupied:
                continue

            if int(monitor.get("x", 0) or 0) < int(center.get("x", 0) or 0):
                profile = profiles["@LEFT@"]
            else:
                profile = profiles["@RIGHT@"]

            bars.append(
                (
                    int(monitor.get("x", 0) or 0),
                    prepare_bar(
                        profile,
                        monitor,
                        [],
                        position="top",
                        dynamic_workspaces=True,
                    ),
                )
            )

    result = [
        bar
        for _, bar in sorted(
            bars,
            key=lambda item: item[0],
        )
    ]

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
