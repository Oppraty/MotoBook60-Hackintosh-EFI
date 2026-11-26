#!/usr/bin/env python3
"""Apply the tested WhateverXe display build to a generated OpenCore EFI.

The bundled WhateverXe build targets the tested Samsung 2880x1800 OLED panel. Use --kext for another panel.
Run with Python 3 (the 1401 engine Python works on Windows).
"""
import argparse
import hashlib
import plistlib
import shutil
import sys
from pathlib import Path

EXPECT_WEX = "fb2f6bb995f951acb5df501892ae1281c54e5062dffcd0599ad4121496b07546"
DISPLAY_ARGS = (
    "-allow3d -disablegfxfirmware -igfxdvmt "
    "-wex-tgl-edp-keep -wex-panel-gop -wex-edp-auxbl"
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("efi", type=Path, help="EFI root containing OC/config.plist")
    ap.add_argument("--kext", type=Path, default=None,
                    help="WhateverXe.kext to install (default: this repo's OC/Kexts copy)")
    ap.add_argument("--confirm-matching-panel", action="store_true",
                    help="acknowledge the bundled kext targets the tested Samsung 2880x1800 OLED panel")
    ap.add_argument("--yes", action="store_true", help="confirm changes")
    args = ap.parse_args()

    if not args.confirm_matching_panel:
        print("WARNING: the bundled WhateverXe build targets the tested Samsung 2880x1800 OLED panel.", file=sys.stderr)
        print("For another panel, build a matching kext and pass --kext. Continuing.", file=sys.stderr)
    if not args.yes:
        print("ERROR: requires --yes. This edits config.plist and replaces WhateverXe.kext.", file=sys.stderr)
        return 1

    efi = args.efi.resolve()
    config = efi / "OC" / "config.plist"
    if not config.is_file():
        print(f"ERROR: missing {config}", file=sys.stderr)
        return 1

    kext = args.kext or (Path(__file__).resolve().parent.parent / "OC" / "Kexts" / "WhateverXe.kext")
    kext = kext.resolve()
    binary = kext / "Contents" / "MacOS" / "WhateverXe"
    if not binary.is_file():
        print(f"ERROR: missing {binary}", file=sys.stderr)
        return 1
    if args.kext is None and sha(binary) != EXPECT_WEX:
        print("ERROR: bundled WhateverXe hash mismatch", file=sys.stderr)
        return 1

    data = plistlib.loads(config.read_bytes())
    additions = data["Kernel"]["Add"]
    names = [e.get("BundlePath") for e in additions]
    if "Lilu.kext" not in names:
        print("ERROR: Lilu.kext not in config Kernel/Add", file=sys.stderr)
        return 1

    target = efi / "OC" / "Kexts" / "WhateverXe.kext"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(kext, target)

    additions[:] = [e for e in additions
                    if e.get("BundlePath") not in ("WhateverXe.kext", "WhateverGreen.kext")]
    lilu_index = next(i for i, e in enumerate(additions) if e.get("BundlePath") == "Lilu.kext")
    additions.insert(lilu_index + 1, {
        "Arch": "Any",
        "BundlePath": "WhateverXe.kext",
        "Comment": "Custom WhateverXe for tested 2880x1800 OLED panel",
        "Enabled": True,
        "ExecutablePath": "Contents/MacOS/WhateverXe",
        "MaxKernel": "",
        "MinKernel": "",
        "PlistPath": "Contents/Info.plist",
    })

    guid = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
    boot = data["NVRAM"]["Add"][guid]["boot-args"]
    if isinstance(boot, bytes):
        boot = boot.decode()
    existing = boot.split()
    for token in DISPLAY_ARGS.split():
        if token not in existing:
            existing.append(token)
    # WhateverGreen boot args are not used with WhateverXe.
    existing = [t for t in existing if not t.startswith("-igfxonln")]
    data["NVRAM"]["Add"][guid]["boot-args"] = " ".join(existing).encode()

    config.write_bytes(plistlib.dumps(data))
    print(f"Patched {config}")
    print("WhateverXe installed; WhateverGreen removed; display boot args applied.")
    print("Validate with ocvalidate, then boot and verify 120 Hz, Metal 2, and brightness keys.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
