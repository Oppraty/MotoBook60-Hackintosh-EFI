# Full performance build bundle

This directory contains the non-EFI pieces used on the reference machine for the best recorded result (Geekbench 7 `1517 / 8026`). It is **not required to boot macOS** and is **not a generic installer**. It complements `EFI-OC.zip`.

## Contents

- `AuxiliaryKernelExtensions.kc` — auxiliary kernel collection from the reference build. SHA256 `15d4547d01e61036347e7b8840e6bb7bb01a8f269321f3c438d7a5ef34887a80`.
- `LibraryExtensions/` — custom kexts that were loaded from `/Library/Extensions`:
  - `IntelSpeedShiftEPP.kext` — Darwin 24 port; EPP 0, HWP Desired 0, treats Unknown power source as AC.
  - `FanMode.kext` — vendor ACPI `VPCW`/`VPCR`/`DYTC` calls for fan mode and performance profile.
  - `RaplDiag.kext` — read-only RAPL/MSR/MCHBAR diagnostics plus an explicit PL2 writer.
  - `TccOffset.kext` — TCC offset control (`tccoffset=2` boot arg).
  - `RazerSSTMicrophone.kext` — ported internal DMIC driver. **Does not publish on MacPro7,1**; use a laptop SMBIOS if the mic matters.
- `scripts/` and `bin/` — root helper and LaunchDaemons:
  - `fanmode-set4.sh` — sets fan mode 4 and DYTC performance at boot.
  - `fanmode-set` — setuid helper accepting only modes 0/1/2/4.
  - `razermic-publish.sh` + `razermic-publish-helper` — one-shot mic publisher.
  - `local.fanmode4.plist`, `local.razermicpublish.plist` — LaunchDaemons.

## Important warnings

- These are custom, ad-hoc-signed kexts. The reference machine used `csr-active-config = 03 08 00 00` (allows untrusted kexts and filesystem access). Do not enable that casually.
- Do not restore a mapped kernel collection over a running system. If you reuse `AuxiliaryKernelExtensions.kc`, do it from recovery with a verified backup and rebuild for your own machine where possible.
- `fanmode-set` must be `root:wheel 4755` if the menu-bar helper is used; otherwise leave it non-setuid and use root-only scripts.
- Never run `kmutil unload` on this stack: live unload caused a kernel panic during testing.
- This bundle will not reproduce the score by itself; the saved EFI, matching panel/CPU, AC power, fan cooling, and clean background load also mattered.

## Install layout (reference only)

```
/Library/Extensions/<kext bundles>        root:wheel
/usr/local/sbin/fanmode-set4.sh           root:wheel 755
/usr/local/sbin/fanmode-set               root:wheel 4755
/usr/local/sbin/razermic-publish.sh       root:wheel 755
/usr/local/sbin/razermic-publish-helper    root:wheel 755
/Library/LaunchDaemons/local.fanmode4.plist
/Library/LaunchDaemons/local.razermicpublish.plist
```

Rebuild the auxiliary KC from `/Library/Extensions` with `kmutil create` after installing the kexts, then reboot. Verify with `kmutil showloaded --list-only`.

`MANIFEST.sha256` lists hashes for every file in this bundle.
