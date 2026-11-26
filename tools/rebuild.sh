#!/bin/bash
# Rebuild a reference-equivalent Moto Book 60 macOS layout from this repository.
# Does not modify the live system. Identity values are supplied by the caller.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EFI_ZIP="$ROOT/EFI-OC.zip"
FULL_DIR="$ROOT/full"
OUT="$PWD/mb60-rebuild"
IDENTITY=""
KEEP_PLACEHOLDER=0
BUILD_AUXKC=0
AUXKC_OUT=""
OCVALIDATE="${OCVALIDATE:-}"

EXPECT_ZIP="adb2ae75166fd1a2eea721a4518acd363f73b1833d137793f706eca1f1f4f1e2"
EXPECT_CONFIG="343ee1c60ae170235a1e7085a144f4724219e7c6c3314396441f3a4361151199"
EXPECT_AUXKC="15d4547d01e61036347e7b8840e6bb7bb01a8f269321f3c438d7a5ef34887a80"
EXPECT_WEX="fb2f6bb995f951acb5df501892ae1281c54e5062dffcd0599ad4121496b07546"

usage() {
  cat <<'USAGE'
Usage: rebuild.sh [options]
  --out DIR              staging directory (default: ./mb60-rebuild)
  --identity FILE        JSON with SystemSerialNumber, MLB, SystemUUID, ROM
                         (ROM is 12 hex chars / 6 bytes)
  --keep-placeholder     leave sanitized PlatformInfo values unchanged
  --build-auxkc FILE     also build an auxiliary KC to FILE (macOS only)
  --ocvalidate PATH      ocvalidate binary (or set OCVALIDATE env)
  -h, --help             show this help

The script only writes into the staging directory. It never touches the live ESP
or kernel collection. Review the staged files before booting from USB.
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    --keep-placeholder) KEEP_PLACEHOLDER=1; shift ;;
    --build-auxkc) BUILD_AUXKC=1; AUXKC_OUT="$2"; shift 2 ;;
    --ocvalidate) OCVALIDATE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[ -f "$EFI_ZIP" ] || die "missing $EFI_ZIP"
[ -d "$FULL_DIR" ] || die "missing $FULL_DIR"
[ "$(sha "$EFI_ZIP")" = "$EXPECT_ZIP" ] || die "EFI-OC.zip hash mismatch"
[ "$(sha "$FULL_DIR/AuxiliaryKernelExtensions.kc")" = "$EXPECT_AUXKC" ] || die "AuxKC hash mismatch"

mkdir -p "$OUT"
rm -rf "$OUT/EFI" "$OUT/full-install"
mkdir -p "$OUT/full-install"
unzip -oq "$EFI_ZIP" -d "$OUT"
[ "$(sha "$OUT/EFI/OC/config.plist")" = "$EXPECT_CONFIG" ] || die "published config hash mismatch"
[ "$(sha "$OUT/EFI/OC/Kexts/WhateverXe.kext/Contents/MacOS/WhateverXe")" = "$EXPECT_WEX" ] || die "WhateverXe hash mismatch"

cp -R "$FULL_DIR/LibraryExtensions" "$OUT/full-install/LibraryExtensions"
cp -R "$FULL_DIR/scripts" "$OUT/full-install/scripts"
cp -R "$FULL_DIR/bin" "$OUT/full-install/bin"
cp "$FULL_DIR/AuxiliaryKernelExtensions.kc" "$OUT/full-install/"
cp "$FULL_DIR/README.md" "$OUT/full-install/README.md"

if [ "$KEEP_PLACEHOLDER" -eq 0 ]; then
  if [ -z "$IDENTITY" ]; then
    echo "WARNING: no --identity supplied; sanitized placeholder identifiers remain."
    echo "Generate your own serial/MLB/UUID/ROM before daily use."
  else
    [ -f "$IDENTITY" ] || die "identity file not found: $IDENTITY"
    python3 - "$OUT/EFI/OC/config.plist" "$IDENTITY" <<'PY'
import json,plistlib,sys,re
cfg,ident=sys.argv[1:]
data=json.load(open(ident))
required=('SystemSerialNumber','MLB','SystemUUID','ROM')
for k in required:
    if k not in data: raise SystemExit(f'identity missing {k}')
if not re.fullmatch(r'[0-9A-Fa-f]{12}', data['ROM']):
    raise SystemExit('ROM must be 12 hex chars (6 bytes)')
d=plistlib.load(open(cfg,'rb'))
g=d['PlatformInfo']['Generic']
for k in required[:-1]: g[k]=data[k]
g['ROM']=bytes.fromhex(data['ROM'])
with open(cfg,'wb') as f: f.write(plistlib.dumps(d))
print('applied supplied PlatformInfo identity')
PY
  fi
fi

if [ -n "$OCVALIDATE" ] || command -v ocvalidate >/dev/null 2>&1; then
  OCV="${OCVALIDATE:-$(command -v ocvalidate)}"
  "$OCV" "$OUT/EFI/OC/config.plist" || die "ocvalidate failed"
else
  echo "ocvalidate not found; skipping config validation."
fi

if [ "$BUILD_AUXKC" -eq 1 ]; then
  [ -n "$AUXKC_OUT" ] || die "--build-auxkc requires an output path"
  command -v kmutil >/dev/null 2>&1 || die "kmutil not available on this system"
  echo "Building auxiliary KC at $AUXKC_OUT (macOS only)"
  kmutil create -n aux --volume-root / --allow-missing-kdk \
    --kernel /System/Library/Kernels/kernel \
    -B /System/Library/KernelCollections/BootKernelExtensions.kc \
    -S /System/Library/KernelCollections/SystemKernelExtensions.kc \
    --repository "$OUT/full-install/LibraryExtensions" \
    --repository /Library/Apple/System/Library/Extensions \
    -A "$AUXKC_OUT"
fi

cat <<DONE

Staged reference-equivalent build at: $OUT

  EFI/OC/                  OpenCore config + kexts + ACPI + drivers
  full-install/            AuxKC, custom kexts, scripts, helpers, plists

Next steps:
  1. Run ocvalidate on $OUT/EFI/OC/config.plist.
  2. Set your own PlatformInfo identity (or pass --identity).
  3. Boot a USB installer with $OUT/EFI before changing the internal ESP.
  4. Review full-install/README.md before installing the non-EFI pieces.
  5. Verify hashes and keep a separate recovery USB.

This script does not create a literal clone of another machine's identities.
DONE
