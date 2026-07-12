#!/usr/bin/env bash
# Copia os assets canônicos de assets/ para o references/ de cada skill que os consome.
# Fonte única de verdade: assets/. Mapeamento em scripts/asset-map.sh.
# Rodado automaticamente pelo pre-commit hook; pode ser rodado à mão também.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "scripts/asset-map.sh"

for entry in "${ASSET_MAP[@]}"; do
  read -r src skills <<< "$entry"
  base="$(basename "$src")"
  for s in $skills; do
    mkdir -p "skills/$s/references"
    cp "$src" "skills/$s/references/$base"
  done
done

echo "sync-assets: ok"
