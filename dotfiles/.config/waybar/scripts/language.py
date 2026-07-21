#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path


def emit(layout: str) -> None:
    low = layout.lower()
    if any(token in low for token in ("russian", "рус", " ru", "ru ", "ru_", "ru-")) or low == "ru":
        text, cls = "🇷🇺 RU", "ru"
    elif any(token in low for token in ("english", "us", "en")):
        text, cls = "🇺🇸 EN", "en"
    else:
        short = (layout or "??").split()[0][:3].upper()
        text, cls = short, "other"
    print(json.dumps({"text": text, "tooltip": layout or "Unknown layout", "class": cls}, ensure_ascii=False), flush=True)


def current_layout() -> str:
    try:
        raw = subprocess.check_output(["hyprctl", "-j", "devices"], text=True, stderr=subprocess.DEVNULL)
        data = json.loads(raw)
        keyboards = data.get("keyboards", [])
        ordered = [k for k in keyboards if k.get("main")] + keyboards
        for keyboard in ordered:
            layout = str(keyboard.get("active_keymap", "")).strip()
            if layout:
                return layout
    except Exception:
        pass
    return "Unknown"


def socket_path() -> Path | None:
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not runtime or not signature:
        return None
    candidates = [
        Path(runtime) / "hypr" / signature / ".socket2.sock",
        Path("/tmp/hypr") / signature / ".socket2.sock",
    ]
    return next((path for path in candidates if path.exists()), None)


def run_events(path: Path) -> None:
    last = current_layout()
    emit(last)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as conn:
        conn.connect(str(path))
        with conn.makefile("r", encoding="utf-8", errors="replace") as stream:
            for line in stream:
                line = line.rstrip("\n")
                if not line.startswith("activelayout>>"):
                    continue
                payload = line.split(">>", 1)[1]
                layout = payload.split(",", 1)[1].strip() if "," in payload else payload.strip()
                if layout and layout != last:
                    last = layout
                    emit(layout)


def run_polling() -> None:
    last = ""
    while True:
        layout = current_layout()
        if layout != last:
            last = layout
            emit(layout)
        time.sleep(1)


while True:
    try:
        path = socket_path()
        if path:
            run_events(path)
        else:
            run_polling()
    except BrokenPipeError:
        raise SystemExit(0)
    except Exception:
        time.sleep(1)
