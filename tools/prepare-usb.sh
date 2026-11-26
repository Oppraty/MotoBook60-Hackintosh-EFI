#!/bin/bash
# Prepare a FAT32 USB EFI with this repo's BOOT/ and OC/.
# Usage: tools/prepare-usb.sh /Volumes/USB-EFI [identity.json]
# If no identity is given, a fresh one is generated into identity.generated.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USB=""
IDENTITY=""
CONFIRM_HW=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --confirm-matching-hardware) CONFIRM_HW=1; shift ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 --confirm-matching-hardware /Volumes/USB-EFI [identity.json]"; exit 0 ;;
    *) USB="$1"; shift ;;
  esac
done
[ -n "$USB" ] || { echo "Usage: $0 --confirm-matching-hardware /Volumes/USB-EFI [identity.json]" >&2; exit 1; }
if [ "$CONFIRM_HW" -ne 1 ]; then
  echo "ERROR: confirm this machine matches the tested SKU with --confirm-matching-hardware" >&2
  echo "Moto Book 60 has multiple CPU/panel variants. This EFI is only for 83J7 / Core 7 240H / 8086:A7AB / Samsung 2880x1800 OLED / 10EC:8922 / 0BDA:D922." >&2
  echo "Other builds: generate a custom EFI with nullmoth/1401 (https://github.com/nullmoth/1401)." >&2
  exit 1
fi
[ -d "$USB/EFI" ] || { echo "ERROR: $USB/EFI not found" >&2; exit 1; }

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
EXPECT_BOOT="d0163dfbe5d2ea46aececd7d7349acfa5b75dfed2993e8489816f3dda71914c8"
EXPECT_OC="9ef21f9d846a992c030fa5858736a6d9efa70a3b4ad88b8d747338bb457b14d4"
EXPECT_CFG="343ee1c60ae170235a1e7085a144f4724219e7c6c3314396441f3a4361151199"
EXPECT_WEX="fb2f6bb995f951acb5df501892ae1281c54e5062dffcd0599ad4121496b07546"

[ "$(sha "$ROOT/BOOT/BOOTx64.efi")" = "$EXPECT_BOOT" ] || { echo "ERROR: BOOTx64.efi hash mismatch"; exit 1; }
[ "$(sha "$ROOT/OC/OpenCore.efi")" = "$EXPECT_OC" ] || { echo "ERROR: OpenCore.efi hash mismatch"; exit 1; }
[ "$(sha "$ROOT/OC/config.plist")" = "$EXPECT_CFG" ] || { echo "ERROR: config.plist hash mismatch"; exit 1; }
[ "$(sha "$ROOT/OC/Kexts/WhateverXe.kext/Contents/MacOS/WhateverXe")" = "$EXPECT_WEX" ] || { echo "ERROR: WhateverXe hash mismatch"; exit 1; }

if [ -z "$IDENTITY" ]; then
  IDENTITY="$ROOT/identity.generated.json"
  python3 - "$IDENTITY" <<'PY'
import json,random,string,sys,uuid
def s(n): return ''.join(random.choice(string.ascii_uppercase+string.digits) for _ in range(n))
data={
 'SystemSerialNumber':'C02'+s(10),
 'MLB':'C02'+s(14),
 'SystemUUID':str(uuid.uuid4()).upper(),
 'ROM':''.join(random.choice('0123456789ABCDEF') for _ in range(12)),
}
json.dump(data,open(sys.argv[1],'w'),indent=2)
print('generated',sys.argv[1])
PY
fi
[ -f "$IDENTITY" ] || { echo "ERROR: identity file not found: $IDENTITY"; exit 1; }

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$USB/EFI.before-$STAMP"
cp -R "$USB/EFI" "$BACKUP"
echo "backup: $BACKUP"

rm -rf "$USB/EFI/BOOT" "$USB/EFI/OC"
mkdir -p "$USB/EFI"
cp -R "$ROOT/BOOT" "$USB/EFI/BOOT"
cp -R "$ROOT/OC" "$USB/EFI/OC"

python3 - "$USB/EFI/OC/config.plist" "$IDENTITY" <<'PY'
import json,plistlib,re,sys
cfg,ident=sys.argv[1:]
d=json.load(open(ident))
required=('SystemSerialNumber','MLB','SystemUUID','ROM')
for k in required:
    if k not in d: raise SystemExit(f'identity missing {k}')
if not re.fullmatch(r'[0-9A-Fa-f]{12}',d['ROM']): raise SystemExit('ROM must be 12 hex chars')
p=plistlib.load(open(cfg,'rb'))
g=p['PlatformInfo']['Generic']
for k in required[:-1]: g[k]=d[k]
g['ROM']=bytes.fromhex(d['ROM'])
with open(cfg,'wb') as f: f.write(plistlib.dumps(p))
print('identity applied')
PY

OCV="${OCVALIDATE:-$(command -v ocvalidate || true)}"
if [ -n "$OCV" ]; then "$OCV" "$USB/EFI/OC/config.plist"; else echo "ocvalidate not found; skipped"; fi
cat <<EOF

USB EFI prepared at $USB/EFI
Identity: $IDENTITY
Boot from the USB with the firmware picker (F12/Esc).

Next: verify display, input, Wi-Fi, Bluetooth, and audio. Copy to internal ESP only after a clean boot.
EOF
