#!/bin/bash
# Overlay a staged reference EFI/OC onto a 1401-created USB EFI volume.
# Keeps EFI/BOOT and all other boot entries. Does not touch the internal ESP.
set -euo pipefail

USB=""
STAGING="./mb60-rebuild"
CONFIRM=0

usage() {
  cat <<'USAGE'
Usage: overlay-1401.sh --usb /Volumes/USB-EFI --staging DIR [--yes]
  --usb PATH       mounted EFI volume of the 1401 USB stick
  --staging DIR    output directory from tools/rebuild.sh
  --yes            confirm replacement of EFI/OC
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}' || echo unknown; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --usb) USB="$2"; shift 2 ;;
    --staging) STAGING="$2"; shift 2 ;;
    --yes) CONFIRM=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[ -n "$USB" ] || die "--usb is required"
[ "$CONFIRM" -eq 1 ] || die "refusing without --yes; see tools/1401-baseline.md"
[ -d "$USB/EFI" ] || die "$USB/EFI not found"
[ -d "$USB/EFI/BOOT" ] || die "$USB/EFI/BOOT not found (expected from 1401)"
[ -d "$STAGING/EFI/OC" ] || die "$STAGING/EFI/OC not found; run tools/rebuild.sh first"

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$USB/EFI.before-mb60-$STAMP"
[ ! -e "$BACKUP" ] || die "backup path already exists: $BACKUP"

echo "USB EFI: $USB/EFI"
echo "Staging: $STAGING/EFI/OC"
echo "BOOTx64.efi (USB):    $(sha "$USB/EFI/BOOT/BOOTx64.efi")"
echo "OpenCore.efi (USB):   $(sha "$USB/EFI/OC/OpenCore.efi" 2>/dev/null || echo missing)"
echo "OpenCore.efi (stage): $(sha "$STAGING/EFI/OC/OpenCore.efi")"
echo "Warning: BOOTx64.efi and OpenCore.efi must come from the same OpenCore release."

cp -R "$USB/EFI" "$BACKUP"
echo "Backed up to $BACKUP"

rm -rf "$USB/EFI/OC"
cp -R "$STAGING/EFI/OC" "$USB/EFI/OC"

cat > "$USB/EFI/MB60-OVERLAY.txt" <<TXT
Moto Book 60 reference EFI overlay applied $STAMP.
Source: Oppraty/MotoBook60-Hackintosh-EFI
$STAGING/EFI/OC replaced the previous EFI/OC.
Previous EFI saved as EFI.before-mb60-$STAMP.
Verify OpenCore version match between EFI/BOOT/BOOTx64.efi and EFI/OC/OpenCore.efi.
TXT

if command -v ocvalidate >/dev/null 2>&1; then
  ocvalidate "$USB/EFI/OC/config.plist" || die "ocvalidate failed after overlay"
else
  echo "ocvalidate not found; validate config.plist before booting."
fi

echo "Done. Boot the USB and verify before touching the internal ESP."
