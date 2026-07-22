#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


def trash_entries() -> list[str]:
    try:
        proc = subprocess.run(
            ["gio", "trash", "--list"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=5,
        )
        if proc.returncode == 0:
            return [line for line in proc.stdout.splitlines() if line.strip()]
    except Exception:
        pass

    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    files = data_home / "Trash/files"
    try:
        return [entry.name for entry in files.iterdir()]
    except OSError:
        return []


entries = trash_entries()
count = len(entries)
if count:
    text = f"󰆴 {count}"
    css_class = "full"
    suffix = "элемент" if count % 10 == 1 and count % 100 != 11 else "элементов"
    tooltip = f"Корзина: {count} {suffix}\nПКМ — открыть\nДвойной ЛКМ — очистить"
else:
    text = "󰩺"
    css_class = "empty"
    tooltip = "Корзина пуста\nПКМ — открыть"

print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}, ensure_ascii=False))
