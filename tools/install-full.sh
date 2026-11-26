#!/bin/bash
# Install the non-EFI performance bundle from full/ and rebuild AuxKC.
# Requires root. Does not unload kexts. Reboot after running.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FULL="$ROOT/full"
KC=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
[ "$(id -u)" -eq 0 ] || { echo "ERROR: run as root (sudo)" >&2; exit 1; }
[ "${1:-}" = "--yes" ] || { echo "Usage: sudo $0 --yes" >&2; exit 1; }
[ -d "$FULL/LibraryExtensions" ] || { echo "ERROR: missing full bundle" >&2; exit 1; }

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
check() {
  local want="$1" file="$2"
  [ "$(sha "$file")" = "$want" ] || { echo "ERROR: hash mismatch: $file" >&2; exit 1; }
}
check 8b769bec675dbd32e815e6eb0dc13e5dffa65923f53b8a061e570ac65a6c06d6 \
  "$FULL/LibraryExtensions/IntelSpeedShiftEPP.kext/Contents/MacOS/IntelSpeedShiftEPP"
check d261e4a4d386dcc3983dcc026a832a7f36396f2fc250248447df0c30d7678fdf \
  "$FULL/LibraryExtensions/FanMode.kext/Contents/MacOS/FanMode"
check 4bb134f5477d3bde53649ff9b802a5f49c704b24c0c486d418be9199e407b4bc \
  "$FULL/LibraryExtensions/RaplDiag.kext/Contents/MacOS/RaplDiag"
check fea22d8202dc4161146a1132968c30fa4c052e273686a2f9f3453c96a4b99d6a \
  "$FULL/LibraryExtensions/TccOffset.kext/Contents/MacOS/TccOffset"
check 480418c7671c9371929f1ac168f00137744f476c98dcce043bbff9e9428ef452 \
  "$FULL/LibraryExtensions/RazerSSTMicrophone.kext/Contents/MacOS/RazerSSTMicrophone"

STAMP=$(date +%Y%m%d-%H%M%S)
BK=/Library/KernelCollections/AuxiliaryKernelExtensions.kc.before-$STAMP
cp "$KC" "$BK"
echo "backup: $BK"

for k in "$FULL"/LibraryExtensions/*.kext; do
  name=$(basename "$k")
  [ ! -e "/Library/Extensions/$name" ] || mv "/Library/Extensions/$name" "/Library/Extensions/$name.before-$STAMP"
  cp -R "$k" "/Library/Extensions/$name"
  chown -R root:wheel "/Library/Extensions/$name"
done

install -m 755 "$FULL/scripts/fanmode-set4.sh" /usr/local/sbin/fanmode-set4.sh
install -m 755 "$FULL/bin/fanmode-set" /usr/local/sbin/fanmode-set
install -m 755 "$FULL/scripts/razermic-publish.sh" /usr/local/sbin/razermic-publish.sh
install -m 755 "$FULL/bin/publish" /usr/local/sbin/razermic-publish-helper
chown root:wheel /usr/local/sbin/fanmode-set4.sh /usr/local/sbin/fanmode-set \
  /usr/local/sbin/razermic-publish.sh /usr/local/sbin/razermic-publish-helper
chmod 4755 /usr/local/sbin/fanmode-set
for p in "$FULL"/scripts/*.plist; do
  install -m 644 "$p" "/Library/LaunchDaemons/$(basename "$p")"
  chown root:wheel "/Library/LaunchDaemons/$(basename "$p")"
  launchctl load -w "/Library/LaunchDaemons/$(basename "$p")" 2>/dev/null || true
done

NEW=/tmp/AuxKC.full.$STAMP
kmutil create -n aux --volume-root / --allow-missing-kdk \
  --kernel /System/Library/Kernels/kernel \
  -B /System/Library/KernelCollections/BootKernelExtensions.kc \
  -S /System/Library/KernelCollections/SystemKernelExtensions.kc \
  --repository /Library/Extensions --repository /Library/Apple/System/Library/Extensions \
  -A "$NEW"
for id in local.IntelSpeedShiftEPP local.markplacer.FanMode local.markplacer.RaplDiag \
          local.markplacer.TccOffset local.markplacer.RazerSSTMicrophone; do
  kmutil inspect -a x86_64 -A "$NEW" | grep -q "$id" || { echo "ERROR: lost $id" >&2; exit 1; }
done
cp "$NEW" "${KC}.new.$STAMP"
mv -f "${KC}.new.$STAMP" "$KC"

echo "Full bundle installed. Reboot now. Do not unload kexts live."
