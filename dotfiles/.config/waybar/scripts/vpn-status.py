#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess


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


interfaces: list[str] = []

raw = run("ip", "-j", "link", "show")
if raw:
    try:
        for link in json.loads(raw):
            name = str(link.get("ifname", ""))
            kind = str((link.get("linkinfo") or {}).get("info_kind", ""))

            if (
                kind in {"wireguard", "amneziawg", "tun", "tap"}
                or re.match(
                    r"^(awg|wg|tun|tap|amnezia)[0-9_.-]*$",
                    name,
                    re.IGNORECASE,
                )
            ):
                interfaces.append(name)
    except Exception:
        pass

nm_active: list[str] = []

for line in run(
    "nmcli",
    "-t",
    "-e",
    "no",
    "-f",
    "TYPE,NAME",
    "connection",
    "show",
    "--active",
).splitlines():
    kind, separator, name = line.partition(":")
    if separator and kind in {"vpn", "wireguard"} and name:
        nm_active.append(name)

interfaces = sorted(set(interfaces))
nm_active = sorted(set(nm_active))

if interfaces or nm_active:
    text = "󰌾 VPN"
    css_class = "connected"
else:
    text = "󰦞"
    css_class = "disconnected"

tooltip: list[str] = []

if interfaces:
    tooltip.append("Интерфейсы: " + ", ".join(interfaces))

if nm_active:
    tooltip.append("NetworkManager: " + ", ".join(nm_active))

if not tooltip:
    tooltip.append("VPN не подключён")

tooltip.extend(
    [
        "ЛКМ — управление VPN",
        "ПКМ — редактор соединений",
    ]
)

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
