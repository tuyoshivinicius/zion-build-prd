#!/usr/bin/env bash
# Falha se qualquer references/ de skill divergir do asset canônico em assets/.
# Guard contra drift silencioso da autocontenção. Mapeamento em scripts/asset-map.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "scripts/asset-map.sh"

fail=0
for entry in "${ASSET_MAP[@]}"; do
  read -r src skills <<< "$entry"
  base="$(basename "$src")"
  for s in $skills; do
    dest="skills/$s/references/$base"
    if ! diff -q "$src" "$dest" >/dev/null 2>&1; then
      echo "DRIFT: $dest difere de $src"
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "check-assets: sem drift"
else
  echo "check-assets: FALHOU — rode scripts/sync-assets.sh"
  exit 1
fi
