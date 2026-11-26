# Moto Book 60 — macOS daily-driver EFI

Working OpenCore EFI and the path to get there for a Moto Book 60 laptop running macOS 15.8.3 (24H241).

- **EFI:** `EFI-OC.zip` (OpenCore + 27 kexts + ACPI + drivers). Extract to the ESP as `EFI/OC/`.
- **Full guide:** `GUIDE.md` — hardware, boot args, what works, step-by-step recreation, verification, rollback, known limits.
- **Platform info is sanitized.** Generate your own serial / MLB / UUID / ROM before daily use (see guide).

## Quick facts

| Item | Value |
|---|---|
| Display | 2880×1800 @ 120 Hz, 60 Hz menu, AUX brightness (0 failures) |
| Bluetooth | Realtek RTL8922A USB `0BDA:D922`, On, THIRD_PARTY_DONGLE |
| Wi‑Fi | Realtek RTL8922AE PCI `10EC:8922` |
| Ethernet | RTL8152 `0BDA:8152` on hub via built-in ECM |
| CPU | 6P+4E, 16 threads (HT on), IntelHybridCores; CPUFriend/CTR disabled |
| Config (published, sanitized) | SHA256 `343ee1c60ae170235a1e7085a144f4724219e7c6c3314396441f3a4361151199` |
| WhateverXe (published build) | SHA256 `fb2f6bb995f951acb5df501892ae1281c54e5062dffcd0599ad4121496b07546` |
| EFI zip | SHA256 `adb2ae75166fd1a2eea721a4518acd363f73b1833d137793f706eca1f1f4f1e2` |

Published profile uses SMBIOS `MacPro7,1`; the internal mic does not publish on that profile. Use a laptop SMBIOS if the mic matters. Not a universal EFI. It is tied to this machine's SSDT/USB map/kext set. Read the guide before using it.

Licenses: OpenCore (BSD‑3), kexts under their own licenses; WhateverXe is BSD‑3. No firmware blobs are redistributed here beyond what the kext vendors include.
