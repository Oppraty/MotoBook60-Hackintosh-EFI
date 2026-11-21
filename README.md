# Moto Book 60 â macOS daily-driver EFI

Working OpenCore EFI and the path to get there for a Moto Book 60 laptop running macOS 15.8.3 (24H241).

- **EFI:** `EFI-OC.zip` (OpenCore + 27 kexts + ACPI + drivers). Extract to the ESP as `EFI/OC/`.
- **Full guide:** `GUIDE.md` â hardware, boot args, what works, step-by-step recreation, verification, rollback, known limits.
- **Platform info is sanitized.** Generate your own serial / MLB / UUID / ROM before daily use (see guide).

## Quick facts

| Item | Value |
|---|---|
| Display | 2880Ã1800 @ 120 Hz, 60 Hz menu, AUX brightness (0 failures) |
| Bluetooth | Realtek RTL8922A USB `0BDA:D922`, On, THIRD_PARTY_DONGLE |
| WiâFi | Realtek RTL8922AE PCI `10EC:8922` |
| Ethernet | RTL8152 `0BDA:8152` on hub via built-in ECM |
| CPU | 6P+4E, 16 threads (HT on), CPUFriend + CpuTopologyRebuild |
| Config (published, sanitized) | SHA256 `06f3eb63a2fa13ecbfcc13a338cbc140d9cb40a14cf57a7f85f3d6e723412613` |
| WhateverXe (published build) | SHA256 `78ed5bef2ed1041647148e6e05cfec0a8579e31adc56878d4785a5b87195403f` |
| EFI zip | SHA256 `37238556e2808a69fb8ef9dd9f8ac9e5ee8969ee796e49c714cbf20e627c2455` |

Not a universal EFI. It is tied to this machine's SSDT/USB map/kext set. Read the guide before using it.

Licenses: OpenCore (BSDâ3), kexts under their own licenses; WhateverXe is BSDâ3. No firmware blobs are redistributed here beyond what the kext vendors include.
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
| CPU | 6P+4E, 16 threads (HT on), CPUFriend + CpuTopologyRebuild |
| Config (published, sanitized) | SHA256 `06f3eb63a2fa13ecbfcc13a338cbc140d9cb40a14cf57a7f85f3d6e723412613` |
| WhateverXe (published build) | SHA256 `78ed5bef2ed1041647148e6e05cfec0a8579e31adc56878d4785a5b87195403f` |
| EFI zip | SHA256 `37238556e2808a69fb8ef9dd9f8ac9e5ee8969ee796e49c714cbf20e627c2455` |

Not a universal EFI. It is tied to this machine's SSDT/USB map/kext set. Read the guide before using it.

Licenses: OpenCore (BSD‑3), kexts under their own licenses; WhateverXe is BSD‑3. No firmware blobs are redistributed here beyond what the kext vendors include.
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
| CPU | 6P+4E, 16 threads (HT on), CPUFriend + CpuTopologyRebuild |
| Config (published, sanitized) | SHA256 `06f3eb63a2fa13ecbfcc13a338cbc140d9cb40a14cf57a7f85f3d6e723412613` |
| WhateverXe (published build) | SHA256 `78ed5bef2ed1041647148e6e05cfec0a8579e31adc56878d4785a5b87195403f` |
| EFI zip | SHA256 `37238556e2808a69fb8ef9dd9f8ac9e5ee8969ee796e49c714cbf20e627c2455` |

Not a universal EFI. It is tied to this machine's SSDT/USA map/kext set. Read the guide before using it.

Licenses: OpenCore (BSD‑3), kexts under their own licenses; WhateverXe is BSD‑3. No firmware blobs are redistributed here beyond what the kext vendors include.
# Moto Book 60 - macOS daily-driver EFI

Working OpenCore EFI and the path to get there for a Moto Book 60 laptop running macOS 15.8.3 (24H241).

- EFI: EFI-OC.zip (OpenCore + 27 kexts + ACPI + drivers). Extract to the ESP as EFI/OC/.
- Full guide: GUIDE.md - hardware, boot args, what works, step-by-step recreation, verification, rollback, known limits.
- Platform info is sanitized. Generate your own serial / MLB / UUID / ROM before daily use (see guide).

## Quick facts

| Item | Value |
|---|---|
| Display | 2880x1800 @ 120 Hz, 60 Hz menu, AUX brightness (0 failures) |
| Bluetooth | Realtek RTL8922A USB 0BDA:D922, On, THIRD_PARTY_DONGLE |
| Wi-Fi | Realtek RTL8922AE PCI 10EC:8922 |
| Ethernet | RTL8152 0BDA:8152 on hub via built-in ECM |
| CPU | 6P+4E, 16 threads (HT on), CPUFriend + CpuTopologyRebuild |
| Config (published, sanitized) | SHA256 06f3eb63a2fa13ecbfcc13a338cbc140d9cb40a14cf57a7f85f3d6e723412613 |
| WhateverXe (published build) | SHA256 78ed5bef2ed1041647148e6e05cfec0a8579e31adc56878d4785a5b87195403f |
| EFI zip | SHA256 37238556e2808a69fb8ef9dd9f8ac9e5ee8969ee796e49c714cbf20e627c2455 |

Not a universal EFI. It is tied to this machine's SSDT/USB map/kext set. Read the guide before using it.

Licenses: OpenCore (BSD-3), kexts under their own licenses; WhateverXe is BSD-3. No firmware blobs are redistributed here beyond what the kext vendors include.
