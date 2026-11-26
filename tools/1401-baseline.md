# Optional 1401 baseline

[nullmoth/1401](https://github.com/nullmoth/1401) is a Windows tool that scans hardware, builds a basic OpenCore setup with OpCore-Simplify, and writes a macOS installer USB. It is useful for getting a known-bootable baseline and for seeing how a tool interprets this machine's hardware.

It does **not** reproduce this build. It will not supply the custom WhateverXe 120 Hz panel binary, Realtek Wi‑Fi/Bluetooth stack, internal DMIC driver, or the custom EPP/FanMode/RaplDiag/TccOffset auxiliary kernel collection. Use it as a starting point, then overlay this repository's reference EFI.

## Workflow

1. On Windows, download `1401-Windows-<version>.zip` from the 1401 releases page, unzip it, and run `1401.exe` as administrator.
2. Click **Check this PC**, then **Build the Mac setup**, read the BIOS steps, then **Create the macOS stick** with a 4 GB+ USB drive.
3. Restart, apply the BIOS settings, boot the stick, and confirm the macOS installer starts. Do not install macOS yet if you only want to validate the baseline.
4. On macOS or from another computer, build this repository's staging tree:
   ```bash
   ./tools/rebuild.sh --out ./mb60-rebuild --identity ./my-identity.json
   ```
5. Plug the 1401 stick back in, find its EFI volume, and overlay only `EFI/OC`:
   ```bash
   ./tools/overlay-1401.sh --usb /Volumes/<USB-EFI> --staging ./mb60-rebuild --yes
   ```
   The script keeps `EFI/BOOT` and other boot entries, backs up the old `EFI`, and replaces `EFI/OC` with the staged copy.

## Important

- Do not mix OpenCore versions between `EFI/BOOT/BOOTx64.efi` and `EFI/OC/OpenCore.efi`. If 1401 used a different OpenCore release, use the matching `BOOTx64.efi` or rebuild the stick from one release. The overlay script prints both hashes so you can check.
- After overlaying, re-run `ocvalidate` on `EFI/OC/config.plist`.
- Use your own PlatformInfo identity. Never clone another machine's serial, MLB, UUID, or ROM.
- Keep the original 1401 stick or the backup directory as recovery.
- 1401 is under the PolyForm Noncommercial License; third-party components keep their own licenses.
