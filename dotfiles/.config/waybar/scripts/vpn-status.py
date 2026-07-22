#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from typing import Any


def run(*args: str) -> str:
    try:
        return subprocess.check_output(
            args,
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=4,
        )
    except Exception:
        return ""


def is_up(link: dict[str, Any]) -> bool:
    flags = {
        str(flag).upper()
        for flag in link.get("flags", [])
    }
    return "UP" in flags


def is_tunnel(name: str, kind: str) -> bool:
    if kind in {
        "wireguard",
        "amneziawg",
        "tun",
        "tap",
    }:
        return True

    return bool(
        re.match(
            r"^(?:"
            r"amn|amnezia|amneziawg|"
            r"awg|wg|tun|tap|vpn"
            r")[0-9_.-]*$",
            name,
            re.IGNORECASE,
        )
    )


interfaces: list[dict[str, str]] = []

raw = run("ip", "-j", "-d", "addr", "show")

if raw:
    try:
        links = json.loads(raw)

        if isinstance(links, list):
            for link in links:
                if not isinstance(link, dict):
                    continue

                name = str(link.get("ifname", ""))
                kind = str(
                    (link.get("linkinfo") or {})
                    .get("info_kind", "")
                )

                if (
                    name
                    and name != "lo"
                    and is_up(link)
                    and is_tunnel(name, kind)
                ):
                    interfaces.append(
                        {
                            "name": name,
                            "kind": kind,
                        }
                    )
    except Exception:
        pass


nm_active: list[dict[str, str]] = []

for line in run(
    "nmcli",
    "-t",
    "-e",
    "no",
    "-f",
    "TYPE,NAME,DEVICE",
    "connection",
    "show",
    "--active",
).splitlines():
    parts = line.split(":", 2)

    if len(parts) != 3:
        continue

    kind, name, device = parts

    if kind in {
        "vpn",
        "wireguard",
        "tun",
    }:
        nm_active.append(
            {
                "type": kind,
                "name": name,
                "device": device,
            }
        )


interface_names = sorted(
    {
        item["name"]
        for item in interfaces
    }
)

awg_active = any(
    item["kind"] == "amneziawg"
    or re.match(
        r"^awg[0-9_.-]*$",
        item["name"],
        re.IGNORECASE,
    )
    for item in interfaces
)

amnezia_active = any(
    re.match(
        r"^(?:amn|amnezia)[0-9_.-]*$",
        item["name"],
        re.IGNORECASE,
    )
    for item in interfaces
) or any(
    re.match(
        r"^(?:amn|amnezia)[0-9_.-]*$",
        item["device"],
        re.IGNORECASE,
    )
    or "amnezia" in item["name"].lower()
    for item in nm_active
)

connected = bool(
    interfaces
    or nm_active
)


if awg_active:
    text = "󰌾 AWG"
    css_class = "awg"
    status_text = "AmneziaWG подключён"
elif amnezia_active:
    text = "󰌾 AMN"
    css_class = "connected"
    status_text = "AmneziaVPN подключён"
elif connected:
    text = "󰌾 VPN"
    css_class = "connected"
    status_text = "VPN подключён"
else:
    text = "󰦞"
    css_class = "disconnected"
    status_text = "VPN не подключён"


tooltip: list[str] = [status_text]

if interfaces:
    formatted = []

    for item in interfaces:
        if item["kind"]:
            formatted.append(
                f'{item["name"]} ({item["kind"]})'
            )
        else:
            formatted.append(item["name"])

    tooltip.append(
        "Интерфейсы: " + ", ".join(formatted)
    )

if nm_active:
    formatted_nm = []

    for item in nm_active:
        description = item["name"]

        if item["device"]:
            description += f' → {item["device"]}'

        formatted_nm.append(description)

    tooltip.append(
        "NetworkManager: " + ", ".join(formatted_nm)
    )


route = run(
    "ip",
    "route",
    "get",
    "1.1.1.1",
).splitlines()

if route:
    match = re.search(
        r"\bdev\s+(\S+)",
        route[0],
    )

    if match:
        route_device = match.group(1)

        if route_device in interface_names:
            tooltip.append(
                f"Интернет-маршрут: {route_device}"
            )


tooltip.append("ЛКМ — меню VPN")

print(
    json.dumps(
        {
            "text": text,
            "tooltip": "\n".join(tooltip),
            "class": css_class,
        },
        ensure_ascii=False,
    )
)
