# Moto Book 60 — macOS daily-driver build guide

How this machine was brought to a stable macOS 15.8.3 (24H241) daily driver, and how to recreate it. Written from the working EFI; identifiers and personal data removed.

## 1. Hardware and target

| Component | ID | Notes |
|---|---|---|
| CPU | Intel RPL‑P/U, 6 P‑cores + 4 E‑cores | Hyper‑Threading enabled in firmware |
| iGPU | PCI `8086:A7AB`, revision 4 (decimal 42923) | OLED 2880×1800 internal panel, single 60 Hz EDID timing |
| Wi‑Fi | PCI `10EC:8922` (RTL8922AE) | `IO80211FamilyLegacy` + `AirPort_RTW89` + `IOSkywalkFamily` |
| Bluetooth | USB `0BDA:D922` (RTL8922A) | `BlueToolFixup` with Realtek patches |
| Ethernet | USB `0BDA:8152` (RTL8152) on a hub | Built‑in `AppleUSBECMData` via high probe score in firmware kext |
| Audio / input / sensors | — | AppleALC, VoodooPS2, VoodooI2C/HID, SMCBatteryManager, ReYogaSMC |

OS: macOS 15.8.3, OpenCore external ESP, internal NVMe holds the known‑good system.

## 2. Working EFI — what is in the zip

`EFI-OC.zip` contains `EFI/OC/` with:

- `config.plist` (published hash `06f3eb63…`, sanitized platform info)
- `OpenCore.efi`, `Drivers/` (HfsPlus, OpenCanopy, OpenLinuxBoot, OpenRuntime, ResetNvramEntry)
- `ACPI/` — SSDT‑EC, SSDT‑MCHC, SSDT‑PLUG‑ALT, SSDT‑PNLF, SSDT‑RTCAWAC, SSDT‑USBX, SSDT‑XOSI, SSDT‑Disable_Network_RP05
- `Kexts/` (27 kexts): Lilu, WhateverXe, CPUFriend, CPUFriendDataProvider, CpuTopologyRebuild, WhateverXe support (NootedGreen, AMFIPass), BTNameFix, BlueToolFixup, BrightnessKeys, AirPort_RTW89, IO80211FamilyLegacy, IOSkywalkFamily, RTL8922AFirmware, AppleALC, USBToolBox + UTBDefault, XHCI‑unsupported, VirtualSMC, SMCBatteryManager, ReYogaSMC, VoodooPS2Controller, VoodooI2C, VoodooI2CHID
- `Resources/`, `Tools/`

Key binary hashes:

```
78ed5bef2ed1041647148e6e05cfec0a8579e31adc56878d4785a5b87195403f  WhateverXe
36c3897684642942bd0dc60f20ecdf002aa375ce1788fa0cefc5e7282418dd76  CPUFriend
0e36496ff627db53002ad04bd8e1e910909e083e587609fb9b472d5f2d7bde07  CpuTopologyRebuild
6d839f1b4de72f4c90f7d91ae79b7af1f57644e7ebbe55042bbb1cad1ebd34a9  BlueToolFixup
ee6f75463b9e96f079e37a1194f35ae3f64642bc624f39eb6b4d4c012cee5c86  Lilu
8db5ce949e77e534acfbf737d596ecfbbd59cadb519a912894cc6cffe48ceafa  NootedGreen
6193931468fb36abb874912def1e92a6797a31d6212e2c0e4396422b9f6a32c6  RTL8922AFirmware
c5c8dc205a079ee3f90b7875fb5ff622e4f15d32f29cf519123dab2822c422b7  USBToolBox
```

Original (pre‑publication) config hash on the machine: `e1120bdf7782a597df5e7c70d1581628a6d8116ee1359fb2ea49f764d1fddf66`. The published zip is identical except for the four sanitized PlatformInfo values.

**Boot args:**
```
keepsyms=1 -allow3d -disablegfxfirmware -igfxdvmt -wex-tgl-edp-keep -wex-panel-gop -wex-edp-auxbl -btlfxboardid -btlfxallowanyaddr -btlfxrealtek
```
`csr-active-config = 03 08 00 00`, `SecureBootModel = Disabled`.

## 3. How each part was reached

### Display — 120 Hz and AUX brightness
WhateverXe is a Lilu plugin that adopts the firmware's already-programmed framebuffer and keeps the panel alive. Stock upstream could not drive this RPL‑P/U panel at its real timing. The working build is based on upstream tag `0.8.2` (commit `4512191`) with these machine-specific changes:

- `kern_display13_panel_timing.hpp` — new mode: `VerticalBlanking = 80+16+24`, `VerticalSyncOffset = 80`, `RefreshRate = 120`. This publishes a 120 Hz mode plus three scaled HiDPI modes (1920×1200, 1680×1050, 1280×800) while keeping the same 2880×1800@120 wire timing.
- `kern_display13_wm.hpp` — opt-in two-pixels-per-CDCLK watermark bound; 2880×1800@120 needs ~709.6 MHz pixel clock, above the conservative one-pixel bound (~652.8 MHz). Scoped to the kept-panel path.
- `kern_alderlake_n.hpp` and `kern_display13_fb_memory.hpp` — accept 6 bpc on the internal eDP panel and a non-page-aligned scanout byte length (2880×1800 BGRA has a half-page tail).
- `kern_vbt.hpp` — VBT panel type `0xFF` means “not selected”; fall back to table entry 0 as Linux i915 does, since this machine's EDID is in OpRegion mailbox 5 with no PNP-ID match.
- `kern_display13_edp_auxbl.hpp` — AUX backlight control; failures measured 0 at both 60 Hz and 120 Hz.
- `kern_xe.cpp/.hpp` — integrate the above, keep the firmware link, publish diagnostics in IORegistry.

The source of these changes is in `Oppraty/WhateverXe`, branch `a7ab-120hz`, commit `66d6b20`. Build with the project's `tools/build.py` against its SDK; verify the binary hash above before installing.

**Result:** Refresh Rate menu shows 120 Hertz / 60 Hertz; switching changes live VTOTAL (`0x077F0707` ↔ `0x0EFF0707`). OS reports 2880×1800 @ 120.00 Hz. AUX brightness failures 0, maxLevel `0x7ff`. The panel's EDID is a single 60 Hz timing; 120 Hz comes from WhateverXe's own raster, not an EDID alternate mode. Lighter scaled modes work; 3840×2400 render caused transient glitches and a BT PoweredOff event, so native 2880×1800 is recommended.

### Bluetooth
The Realtek USB Bluetooth controller needed: `BlueToolFixup` with the Realtek patch set and boot args `-btlfxboardid -btlfxallowanyaddr -btlfxrealtek`, plus `BTNameFix` for idProduct/idVendor. Before this, `bluetoothd` restarted ~135 times per boot; after, it stayed at one PID. State On, real address, Chipset THIRD_PARTY_DONGLE, no crash loop.

### Wi‑Fi and Ethernet
Wi‑Fi works via `10EC:8922` with the legacy 80211 stack + RTW89 driver + Skywalk family. Ethernet on a USB hub (`0BDA:8152`) was made to bind the built-in `AppleUSBECMData` by adding a high-probe-score personality to the loaded `RTL8922AFirmware.kext` Info.plist. IPv4 obtained via DHCP; default route and internet verified.

### CPU
Hyper‑Threading enabled in firmware. `CPUFriend` (with generated DataProvider) raises all-core load frequency; `CpuTopologyRebuild 2.0.2` makes macOS report 6 cores / 16 threads (P-cores as cores, E-cores + SMT as threads). PL1 power limit still caps sustained all-core frequency. EPP/perf-bias `00`, LFM `08`. No panics from this stack.

### Input / power / sensors
`VoodooPS2Controller`, `VoodooI2C` + `VoodooI2CHID` for keyboard/trackpad; `BrightnessKeys` for AUX brightness keys; `SMCBatteryManager` + `ReYogaSMC` for battery/sensors; `USBToolBox` + `UTBDefault` for the USB map.

## 4. Recreation — step by step

1. **Back up everything.** Keep a timestamped copy of the current ESP and of any kext collection you modify. Never edit the internal ESP blind.
2. **Format a spare USB stick** as GPT with a FAT32 EFI partition (≥200 MB).
3. **Extract `EFI-OC.zip`** so the stick has `EFI/OC/` and `EFI/BOOT/` as in the archive. Check for and delete any AppleDouble `._*` files before booting (`dot_clean` or `find … -name '._*' -delete`).
4. **Generate your own PlatformInfo.** In `EFI/OC/config.plist`, `PlatformInfo/Generic`: replace `SystemSerialNumber`, `MLB`, `SystemUUID`, and `ROM` with values generated for your machine (OpenCore Configurator / ProperTree or `macserial`). The published values are placeholders. Keep `SystemProductName = MacBookPro16,2` only if that SMBIOS suits your hardware.
5. **Hash-verify** `config.plist` and any kext you replace. Record SHA256 before and after.
6. **Install OpenCore to the USB ESP** (`bless --mount /Volumes/EFI --setBoot --file /Volumes/EFI/System/Library/CoreServices/boot.efi --shortform` or your preferred installer).
7. **Boot once from USB.** Use the firmware boot picker (F12/Option). Do not write to the ESP while booted from that same stick — it caused hangs in this build.
8. **Verify display and input** in macOS: About This Mac / System Information shows the iGPU; Refresh Rate menu has 60/120; brightness keys work.
9. **Copy the verified `EFI/OC` to the internal ESP only after a clean second boot** from USB. Keep the previous internal `config.plist` as a timestamped backup. One staged reboot per change.
10. **Post-boot checks:** `kmutil showloaded | grep -i WhateverXe`, `ioreg` for `WEX*` properties, `pmset -g`, Bluetooth state, network interfaces, brightness failures.

## 5. Verification and rollback

- Hash every staged asset; keep the hash list next to the EFI.
- One staged reboot per test. If a boot hangs or panics, boot the previously known-good ESP and restore its config from the timestamped backup.
- Never leave AppleDouble files on a FAT32 ESP.
- Before changing kext collections, back up `/Library/KernelCollections/AuxiliaryKernelExtensions.kc`; rebuild only with a repository containing all kexts that were in the old collection.

## 6. Known limits and what did not work

- **AirDrop:** blocked by environment, not code — no Apple device owned; Android Quick Share is not an AWDL peer. Do not chase AWDL flags without an iPhone or second Mac.
- **HDR / Metal 3:** not feasible on this RPL‑P/U Xe‑LP stack; the donor driver predates Metal 3 and 10 bpc is bandwidth-blocked.
- **Vulkan:** system Vulkan (MoltenVK 1.4.2, loader/tools 1.4.363) works for `vulkaninfo` (`0xA7AB`, DRIVER_ID_MOLTENVK). Minecraft's Vulkan backend crashes in the Intel Metal counter buffer; keep OpenGL with `reduce_resolution_on_mac=true`.
- **XeGfx / WTLIntelGfx experiment:** a separate in-progress i915-on-XNU port. It reached GuC firmware load on this iGPU but command transport timed out (`GUC: CT: No response`); not part of the daily driver. Do not install it on the internal system.
- **Scaled 3840×2400 render** caused transient window glitches and a Bluetooth PoweredOff event; prefer native 2880×1800 or the lighter scaled modes.
- **PL1 cap** still limits sustained all-core frequency despite CPUFriend.

## 7. Change log / evidence trail

Published EFI is the state that produced:

- Display: 2880×1800 @120, 60/120 menu, AUX failures 0
- Bluetooth: On, real address, THIRD_PARTY_DONGLE, no crash loop
- Ethernet: `en` interface on RTL8152 with default route
- CPU: 6 cores / 16 threads, no panics
- Wi‑Fi: associated and routed

Hardware IDs and configuration hashes above are observations; conclusions about why a step works are derivations from driver source and registry evidence. Anything not listed as verified (AirDrop, Metal 3, XeGfx stage 4) is explicitly not part of the daily-driver result.
