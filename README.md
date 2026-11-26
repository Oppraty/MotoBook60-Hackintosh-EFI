# Moto Book 60 — macOS daily-driver EFI

Working OpenCore EFI for one Motorola Moto Book 60 (`83J7`, Core 7 240H) running macOS 15.8.3 (24H241). Read `GUIDE.md` before using it.

## New users start here

1. **Check hardware.** This EFI is tied to `83J7`, Core 7 240H, iGPU `8086:A7AB`, Wi‑Fi `10EC:8922`, Bluetooth `0BDA:D922`, and the Samsung 2880×1800 OLED. Other hardware needs different kexts/patches.
2. **Back up.** Make a disk + ESP backup and a separate bootable recovery USB. Do not touch the internal ESP first.
3. **Build a USB stick manually.** Format a USB as GPT/FAT32 with an EFI partition, extract `EFI-OC.zip` to get `EFI/OC/` and `EFI/BOOT/`, delete any `._*` files, generate your own serial/MLB/UUID/ROM in `config.plist`, hash-verify, bless OpenCore to the USB ESP, then boot and verify display/brightness/input/Wi‑Fi/Bluetooth.
4. **Optional full performance.** After a clean boot, read `full/README.md`. It contains custom kexts, helpers and AuxKC used for the best score. EFI alone does not reproduce that result.
5. **Internal install.** Copy only a verified EFI to the internal ESP, preserving other boot entries. Keep the recovery USB.

Detailed steps: `GUIDE.md` §4.

## Repository contents

- `EFI-OC.zip` — OpenCore + 28 kexts + ACPI + drivers. Extract as `EFI/OC/`.
- `full/` — auxiliary KC, custom kexts, helpers and LaunchDaemons for the performance profile. See `full/README.md`.
- `screenshots/` — captured evidence. See `screenshots/README.md`.
- `GUIDE.md` — hardware, boot args, build, verification, rollback, known limits.

## Quick facts

| Item | Value |
|---|---|
| Display | 2880×1800 @ 120 Hz, 60 Hz menu, AUX brightness (0 failures) |
| Bluetooth | Realtek RTL8922A USB `0BDA:D922`, On, THIRD_PARTY_DONGLE |
| Wi‑Fi | Realtek RTL8922AE PCI `10EC:8922` |
| Ethernet | RTL8152 `0BDA:8152` on hub via built-in ECM |
| CPU | 6P+4E, 16 threads, IntelHybridCores; CPUFriend/CTR disabled |
| Config (published, sanitized) | SHA256 `343ee1c60ae170235a1e7085a144f4724219e7c6c3314396441f3a4361151199` |
| WhateverXe (published build) | SHA256 `fb2f6bb995f951acb5df501892ae1281c54e5062dffcd0599ad4121496b07546` |
| EFI zip | SHA256 `adb2ae75166fd1a2eea721a4518acd363f73b1833d137793f706eca1f1f4f1e2` |

Published profile uses SMBIOS `MacPro7,1`; the internal mic does not publish on that profile. Use a laptop SMBIOS if the mic matters. `full/` contains ad-hoc-signed kexts and is not required to boot. Not a universal EFI.

Best recorded Geekbench 7 result: **1517 single / 8026 multi** with the full bundle and maximum fan cooling. AirDrop remains unverified (no Apple peer available). Sleep/wake is not reliable on this stack.

Licenses: OpenCore BSD‑3, kexts under their own licenses, WhateverXe BSD‑3. No machine-specific identifiers are published.
