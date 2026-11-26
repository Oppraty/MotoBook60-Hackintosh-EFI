# Rebuild script

`rebuild.sh` assembles a reference-equivalent layout from this repository into a staging directory. It does not modify the live ESP, kernel collection, or `/Library/Extensions`.

## What it does

1. Verifies `EFI-OC.zip`, the saved AuxKC, the published sanitized config, and the WhateverXe binary against hardcoded SHA256 values.
2. Unpacks `EFI/OC/` into the staging directory.
3. Copies the `full/` bundle into `full-install/` with the reference install layout.
4. Applies your own PlatformInfo identity from a JSON file, or leaves the sanitized placeholders in place with a warning.
5. Optionally runs `ocvalidate` and/or builds an auxiliary kernel collection with `kmutil`.

## Usage

```bash
chmod +x tools/rebuild.sh

# Default: verify and stage with placeholder identifiers
./tools/rebuild.sh --out ./mb60-rebuild

# With your own identity (do not commit this file)
cp tools/identity.example.json my-identity.json
# edit my-identity.json
./tools/rebuild.sh --out ./mb60-rebuild --identity ./my-identity.json \
  --ocvalidate /path/to/ocvalidate

# Optional AuxKC build on macOS
./tools/rebuild.sh --out ./mb60-rebuild --identity ./my-identity.json \
  --build-auxkc ./AuxiliaryKernelExtensions.mine.kc
```

## Identity JSON

See `identity.example.json`. `ROM` must be 12 hex characters (6 bytes), for example `A1B2C3D4E5F6`.

Do **not** commit your real serial, MLB, UUID, ROM, or any generated identity file. The repository intentionally publishes placeholders.

## Scope

This script produces a reference-equivalent layout, not a literal clone. A literal 1:1 copy would require another machine's identifiers and would be inappropriate to publish. It also cannot guarantee hardware-specific results: panel, wireless card, BIOS, macOS build, and background load all matter.
