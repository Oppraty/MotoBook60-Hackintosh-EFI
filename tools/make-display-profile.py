#!/usr/bin/env python3
"""Scan EDID / resolution and generate a WhateverXe display timing profile.

Examples:
  python3 tools/make-display-profile.py --edid-decode edid.txt --patch-source wex-src
  python3 tools/make-display-profile.py --edid panel.bin --out display-profile.json

The built-in profile is for the tested Samsung 2880x1800@120 OLED.
Other panels get a template with the values that can be detected; missing fields stay null.
"""
import argparse
import json
import re
from pathlib import Path

BUILTIN = {
    "name": "Samsung ATNA40HQ01-0 / SDC4203, 2880x1800@120",
    "width": 2880, "height": 1800, "refresh": 120,
    "hfront": 8, "hsync": 32, "hback": 160,
    "vfront": 80, "vsync": 16, "vback": 24,
    "pixel_clock_hz": 709633000,
    "image_width_mm": 302, "image_height_mm": 189,
}


def parse_decode_text(text: str) -> dict:
    out = {}
    m = re.search(r"(\d+)x(\d+)\s+([\d.]+)\s*Hz", text)
    if m:
        out.update(width=int(m.group(1)), height=int(m.group(2)), refresh=float(m.group(3)))
    m = re.search(r"Hfront\s+(\d+)\s+Hsync\s+(\d+)\s+Hback\s+(\d+)", text)
    if m:
        out.update(hfront=int(m.group(1)), hsync=int(m.group(2)), hback=int(m.group(3)))
    m = re.search(r"Vfront\s+(\d+)\s+Vsync\s+(\d+)\s+Vback\s+(\d+)", text)
    if m:
        out.update(vfront=int(m.group(1)), vsync=int(m.group(2)), vback=int(m.group(3)))
    m = re.search(r"([\d.]+)\s*MHz", text)
    if m:
        out["pixel_clock_hz"] = int(float(m.group(1)) * 1_000_000)
    return out


def parse_raw_edid(data: bytes) -> dict:
    # Base EDID detailed timing descriptors at 0x36, 0x48, 0x5a, 0x6c.
    out = {}
    for off in (0x36, 0x48, 0x5A, 0x6C):
        if len(data) < off + 18:
            break
        d = data[off:off + 18]
        pc = int.from_bytes(d[0:2], "little")
        if not pc:
            continue
        h = d[2] | ((d[4] >> 4) << 8)
        hb = d[3] | ((d[4] & 0x0F) << 8)
        v = d[5] | ((d[6] >> 4) << 8)
        vb = d[7] | ((d[8] & 0x0F) << 8)
        if not h or not v:
            continue
        out.update(width=h, height=v, hblank=hb, vblank=vb,
                   pixel_clock_hz=pc * 10_000,
                   hsync=((d[10] >> 5) & 0x03), hfront=((d[10] >> 3) & 0x03))
        out["refresh"] = round(out["pixel_clock_hz"] / ((h + hb) * (v + vb)), 6)
        break
    return out


def match_profile(found: dict) -> dict:
    if found.get("width") == BUILTIN["width"] and found.get("height") == BUILTIN["height"]:
        if found.get("refresh", 0) and abs(found["refresh"] - BUILTIN["refresh"]) < 2:
            p = dict(BUILTIN)
            p["source"] = "built-in profile matched by resolution/refresh"
            return p
    p = dict(found)
    p["source"] = "detected values; unknown fields are null"
    p.setdefault("pixel_clock_hz", None)
    return p


def patch_source(source: Path, p: dict) -> None:
    header = source / "WhateverXe" / "kern_display13_panel_timing.hpp"
    if not header.is_file():
        header = source / "kern_display13_panel_timing.hpp"
    if not header.is_file():
        raise SystemExit(f"timing header not found under {source}")
    s = header.read_text()
    required = ("hfront", "hsync", "hback", "vfront", "vsync", "vback", "pixel_clock_hz")
    if any(p.get(k) is None for k in required):
        raise SystemExit("cannot patch source: timing values incomplete")
    hb = p["hfront"] + p["hsync"] + p["hback"]
    vb = p["vfront"] + p["vsync"] + p["vback"]
    repl = {
        r"HorizontalBlanking\s*=\s*[^,]+": f"HorizontalBlanking = {p['hfront']}+{p['hsync']}+{p['hback']}",
        r"HorizontalSyncOffset\s*=\s*[^,]+": f"HorizontalSyncOffset = {p['hfront']}",
        r"HorizontalSyncPulseWidth\s*=\s*[^,]+": f"HorizontalSyncPulseWidth = {p['hsync']}",
        r"VerticalBlanking\s*=\s*[^,]+": f"VerticalBlanking = {p['vfront']}+{p['vsync']}+{p['vback']}",
        r"VerticalSyncOffset\s*=\s*[^,]+": f"VerticalSyncOffset = {p['vfront']}",
        r"VerticalSyncPulseWidth\s*=\s*[^,]+": f"VerticalSyncPulseWidth = {p['vsync']}",
        r"RefreshRate\s*=\s*\d+": f"RefreshRate = {int(p.get('refresh', 120))}",
        r"PixelClock\s*=\s*\d+ULL": f"PixelClock = {int(p['pixel_clock_hz'])}ULL",
    }
    for pattern, value in repl.items():
        s, n = re.subn(pattern, value, s, count=1)
        if n == 0:
            print(f"warning: pattern not found: {pattern}")
    _ = hb, vb
    header.write_text(s)
    print(f"patched {header}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--edid", type=Path, help="raw EDID binary or hex text")
    ap.add_argument("--edid-decode", type=Path, help="edid-decode text output")
    ap.add_argument("--width", type=int)
    ap.add_argument("--height", type=int)
    ap.add_argument("--refresh", type=float)
    ap.add_argument("--out", type=Path, default=Path("display-profile.json"))
    ap.add_argument("--patch-source", type=Path, help="WhateverXe source tree to patch")
    args = ap.parse_args()

    found = {}
    if args.edid_decode:
        found.update(parse_decode_text(args.edid_decode.read_text(errors="replace")))
    if args.edid:
        raw = args.edid.read_bytes()
        if all(chr(c) in "0123456789abcdefABCDEF" for c in raw[:32]):
            raw = bytes.fromhex(raw.decode().strip())
        found.update(parse_raw_edid(raw))
    if args.width:
        found["width"] = args.width
    if args.height:
        found["height"] = args.height
    if args.refresh:
        found["refresh"] = args.refresh

    profile = match_profile(found)
    args.out.write_text(json.dumps(profile, indent=2) + "\n")
    print(f"wrote {args.out}")
    print(json.dumps(profile, indent=2))
    if args.patch_source:
        patch_source(args.patch_source, profile)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
